from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from .models import DeliveryAssignment, DeliveryBoy, RecycleBag, Activity, Register, DeliveryBoyNotification
import logging

logger = logging.getLogger(__name__)

@receiver(post_save, sender=DeliveryAssignment)
def sync_recycle_bag_status(sender, instance, **kwargs):
    """
    مزامنة حالة RecycleBag مع حالة DeliveryAssignment تلقائيًا.
    """
    if not instance.recycle_bag:
        logger.warning("No RecycleBag associated with DeliveryAssignment")
        return

    if instance.status != instance.recycle_bag.status:
        instance.recycle_bag.status = instance.status
        instance.recycle_bag.save()
        logger.info(f"Synced RecycleBag status to {instance.status} for bag {instance.recycle_bag.id}")

@receiver(post_save, sender=DeliveryAssignment)
def update_delivery_boy_stats(sender, instance, created, **kwargs):
    """
    تحديث إحصائيات الديليفري بوي (عدد الطلبات المكتملة، النقاط، المكافآت)
    """
    if not instance.delivery_boy:
        logger.warning("No DeliveryBoy associated with DeliveryAssignment")
        return

    # تحديث فقط عندما تتغير الحالة إلى 'delivered'
    if not created and instance.status == 'delivered':
        delivery_boy = instance.delivery_boy
        
        # حساب عدد الطلبات المكتملة
        delivered_count = DeliveryAssignment.objects.filter(
            delivery_boy=delivery_boy,
            status='delivered'
        ).count()
        
        logger.info(f"Updating delivery boy stats for {delivery_boy.email}")
        logger.info(f"Previous points: {delivery_boy.points}, Previous rewards: {delivery_boy.rewards}")
        logger.info(f"Total delivered orders: {delivered_count}")
        
        # تحديث عدد الطلبات والنقاط
        delivery_boy.total_orders_delivered = delivered_count
        delivery_boy.points = delivered_count * 10  # 10 نقاط لكل طلب
        
        # حساب المكافآت الأساسية (1 جنيه لكل 20 نقطة)
        base_rewards = delivery_boy.points // 20
        
        # حساب المكافآت الإضافية (50 جنيه لكل 10 طلبات)
        bonus_rewards = (delivered_count // 10) * 50
        
        # إجمالي المكافآت
        delivery_boy.rewards = base_rewards + bonus_rewards
        
        delivery_boy.save()
        logger.info(f"Updated delivery boy stats: points={delivery_boy.points}, rewards={delivery_boy.rewards}")

@receiver(post_save, sender=Activity)
def update_user_points(sender, instance, created, **kwargs):
    """
    تحديث نقاط المستخدم ومكافآته بناءً على الأنشطة.
    """
    if created and instance.user:
        user = instance.user
        logger.info(f"Activity created for user {user.email}: {instance.title}")
        logger.info(f"Previous points: {user.points}, Previous rewards: {user.rewards}")
        
        # حساب إجمالي النقاط من جميع الأنشطة
        total_points = max(sum(activity.points for activity in Activity.objects.filter(user=user)), 0)
        new_rewards = int(total_points / 20)

        logger.info(f"Calculated total points: {total_points}, New rewards: {new_rewards}")

        # تحديث الـ points وrewards فقط لو اتغيرت القيم
        if user.points != total_points or user.rewards != new_rewards:
            user.points = total_points
            user.rewards = new_rewards
            user.save()
            logger.info(f"Updated user {user.email} points via signal: points={user.points}, rewards={user.rewards}")
        else:
            logger.debug(f"No update needed for user {user.email}: points={user.points}, rewards={user.rewards}")

@receiver(pre_save, sender=DeliveryBoy)
def calculate_points_and_rewards(sender, instance, **kwargs):
    """
    حساب النقاط والمكافآت تلقائياً عند تغيير عدد الطلبات المكتملة
    """
    # حساب النقاط (10 نقاط لكل طلب مكتمل)
    new_points = instance.total_orders_delivered * 10
    
    # حساب المكافآت الأساسية (1 جنيه لكل 20 نقطة)
    base_rewards = new_points // 20
    
    # حساب المكافآت الإضافية (50 جنيه لكل 10 طلبات)
    bonus_rewards = (instance.total_orders_delivered // 10) * 50
    
    # إجمالي المكافآت
    new_rewards = base_rewards + bonus_rewards
    
    # تحديث القيم فقط إذا كانت مختلفة
    if instance.points != new_points or instance.rewards != new_rewards:
        instance.points = new_points
        instance.rewards = new_rewards
        logger.info(f"Pre-save signal: Updated {instance.email} stats: orders={instance.total_orders_delivered}, points={new_points}, rewards={new_rewards}")
    else:
        logger.debug(f"No update needed for delivery boy {instance.email}: points={instance.points}, rewards={instance.rewards}")