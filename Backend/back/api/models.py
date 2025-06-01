from django.db import models
from io import BytesIO
import qrcode
from django.core.files import File
from django.utils import timezone
import logging

logger = logging.getLogger(__name__)

# دالة لتحديد مسار تحميل الصورة بناءً على الإيميل
def user_profile_pic_path(instance, filename):
    return f'profile_pics/{instance.email}.png'

def delivery_boy_profile_pic_path(instance, filename):
    return f'delivery_boy_profile_pics/{instance.email}.png'

# نموذج Store
class Store(models.Model):
    CATEGORY_CHOICES = [
        ('hyper markets', 'Hypermarkets'),
        ('cafes', 'Cafes'),
        ('restaurants', 'Restaurants'),
        ('dessert_shops', 'Dessert shops'),
        ('pharmacies', 'Pharmacies'),
    ]
    
    name = models.CharField(max_length=100)
    phone_number = models.CharField(max_length=15)
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

# نموذج Branch
class Branch(models.Model):
    GOVERNORATE_CHOICES = [
        ('alexandria', 'Alexandria'),
        ('aswan', 'Aswan'),
        ('asyut', 'Asyut'),
        (' smash', 'Beheira'),
        ('beni_suef', 'Beni Suef'),
        ('cairo', 'Cairo'),
        ('dakahlia', 'Dakahlia'),
        ('damietta', 'Damietta'),
        ('faiyum', 'Faiyum'),
        ('gharbia', 'Gharbia'),
        ('giza', 'Giza'),
        ('ismailia', 'Ismailia'),
        ('kafr_el_sheikh', 'Kafr El Sheikh'),
        ('luxor', 'Luxor'),
        ('matruh', 'Matruh'),
        ('minya', 'Minya'),
        ('monufia', 'Monufia'),
        ('new_valley', 'New Valley'),
        ('north_sinai', 'North Sinai'),
        ('port_said', 'Port Said'),
        ('qalyubia', 'Bunkerry'),
        ('qena', 'Qena'),
        ('red_sea', 'Red Sea'),
        ('sharqia', 'Sharqia'),
        ('sohag', 'Sohag'),
        ('south_sinai', 'South Sinai'),
        ('suez', 'Suez'),
    ]

    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='branches')
    name = models.CharField(max_length=100)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    phone_number = models.CharField(max_length=15, default="0000000000")
    governorate = models.CharField(max_length=100, choices=GOVERNORATE_CHOICES, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.store.name} - {self.name}"

# نموذج المستخدم العادي
class Register(models.Model):
    GOVERNORATE_CHOICES = [
        ('alexandria', 'Alexandria'),
        ('aswan', 'Aswan'),
        ('asyut', 'Asyut'),
        ('beheira', 'Beheira'),
        ('beni_suef', 'Beni Suef'),
        ('cairo', 'Cairo'),
        ('dakahlia', 'Dakahlia'),
        ('damietta', 'Damietta'),
        ('faiyum', 'Faiyum'),
        ('gharbia', 'Gharbia'),
        ('giza', 'Giza'),
        ('ismailia', 'Ismailia'),
        ('kafr_el_sheikh', 'Kafr El Sheikh'),
        ('luxor', 'Luxor'),
        ('matruh', 'Matruh'),
        ('minya', 'Minya'),
        ('monufia', 'Monufia'),
        ('new_valley', 'New Valley'),
        ('north_sinai', 'North Sinai'),
        ('port_said', 'Port Said'),
        ('qalyubia', 'Qalyubia'),
        ('qena', 'Qena'),
        ('red_sea', 'Red Sea'),
        ('sharqia', 'Sharqia'),
        ('sohag', 'Sohag'),
        ('south_sinai', 'South Sinai'),
        ('suez', 'Suez'),
    ]

    TYPE_CHOICES = [
        ('customer', 'Customer'),
        ('delivery_boy', 'Delivery Boy'),
    ]

    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=50)
    gender = models.CharField(max_length=10)
    email = models.EmailField(max_length=100, unique=True)
    password = models.CharField(max_length=15)
    birth_date = models.DateField()
    phone_number = models.CharField(max_length=15)
    governorate = models.CharField(max_length=100, choices=GOVERNORATE_CHOICES, null=True, blank=True)
    address = models.TextField(null=True, blank=True)
    type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='customer')
    points = models.IntegerField(default=0)
    rewards = models.IntegerField(default=0)
    co2_saved = models.DecimalField(max_digits=10, decimal_places=2, default=0.0)
    items_recycled = models.PositiveIntegerField(default=0)
    image = models.ImageField(upload_to=user_profile_pic_path, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.first_name + ' ' + self.last_name

    class Meta:
        ordering = ['-created_at']

# نموذج الدليفري بوي
class DeliveryBoy(models.Model):
    GOVERNORATE_CHOICES = [
        ('alexandria', 'Alexandria'),
        ('aswan', 'Aswan'),
        ('asyut', 'Asyut'),
        ('beheira', 'Beheira'),
        ('beni_suef', 'Beni Suef'),
        ('cairo', 'Cairo'),
        ('dakahlia', 'Dakahlia'),
        ('damietta', 'Damietta'),
        ('faiyum', 'Faiyum'),
        ('gharbia', 'Gharbia'),
        ('giza', 'Giza'),
        ('ismailia', 'Ismailia'),
        ('kafr_el_sheikh', 'Kafr El Sheikh'),
        ('luxor', 'Luxor'),
        ('matruh', 'Matruh'),
        ('minya', 'Minya'),
        ('monufia', 'Monufia'),
        ('new_valley', 'New Valley'),
        ('north_sinai', 'North Sinai'),
        ('port_said', 'Port Said'),
        ('qalyubia', 'Qalyubia'),
        ('qena', 'Qena'),
        ('red_sea', 'Red Sea'),
        ('sharqia', 'Sharqia'),
        ('sohag', 'Sohag'),
        ('south_sinai', 'South Sinai'),
        ('suez', 'Suez'),
    ]

    TYPE_CHOICES = [
        ('customer', 'Customer'),
        ('delivery_boy', 'Delivery Boy'),
    ]

    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=50)
    gender = models.CharField(max_length=10)
    email = models.EmailField(max_length=100, unique=True)
    password = models.CharField(max_length=15)
    birth_date = models.DateField()
    phone_number = models.CharField(max_length=15)
    governorate = models.CharField(max_length=100, choices=GOVERNORATE_CHOICES, null=True, blank=True)
    type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='delivery_boy')
    points = models.IntegerField(default=0)
    rewards = models.IntegerField(default=0)
    total_orders_delivered = models.PositiveIntegerField(default=0)
    average_rating = models.FloatField(default=0.0)
    image = models.ImageField(upload_to=delivery_boy_profile_pic_path, null=True, blank=True)
    last_activity = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)
    is_available = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.first_name} {self.last_name}"

    @classmethod
    def update_all_points_and_rewards(cls):
        """
        تحديث النقاط والمكافآت لجميع الديليفري بويز
        """
        for delivery_boy in cls.objects.all():
            # حساب النقاط (10 نقاط لكل طلب مكتمل)
            # delivery_boy.points = delivery_boy.total_orders_delivered * 10 # Commented out to allow transactional point changes
            
            # حساب المكافآت (10 جنيه لكل 100 نقطة)
            # Ensure rewards are calculated based on the current, potentially modified, points
            delivery_boy.rewards = delivery_boy.points // 20 # 1 EGP for every 20 points
            
            delivery_boy.save()
        return True

    class Meta:
        ordering = ['-created_at']

# نموذج تقييمات
class DeliveryBoyRating(models.Model):
    recycle_bag = models.ForeignKey('RecycleBag', on_delete=models.CASCADE, related_name='ratings')
    delivery_boy = models.ForeignKey(DeliveryBoy, on_delete=models.CASCADE, related_name='ratings')
    user = models.ForeignKey(Register, on_delete=models.CASCADE, related_name='ratings_given')
    user_rating = models.PositiveIntegerField(null=True, blank=True)
    user_comment = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Rating for Bag {self.recycle_bag.id} by {self.user.email}"

# نموذج إشعارات الـ Delivery Boy
class DeliveryBoyNotification(models.Model):
    delivery_boy = models.ForeignKey(DeliveryBoy, on_delete=models.CASCADE, related_name='notifications')
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)

    def __str__(self):
        return f"Notification for {self.delivery_boy.email} - {self.message}"

    class Meta:
        ordering = ['-created_at']

# نموذج DeliveryBoyVoucher
class DeliveryBoyVoucher(models.Model):
    delivery_boy = models.ForeignKey(DeliveryBoy, on_delete=models.CASCADE, related_name='vouchers')
    code = models.CharField(max_length=20, unique=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    is_used = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    used_branch = models.ForeignKey(Branch, on_delete=models.SET_NULL, null=True, blank=True, related_name='used_vouchers')
    qr_code = models.ImageField(upload_to='delivery_vouchers_qr/', null=True, blank=True)

    def __str__(self):
        return f"Voucher {self.code} for {self.delivery_boy.email}"

    def save(self, *args, **kwargs):
        if not self.expires_at:
            self.expires_at = timezone.now() + timezone.timedelta(hours=48)
        
        # Generate QR code if it doesn't exist
        if not self.qr_code:
            import qrcode
            import io
            from django.core.files.base import ContentFile
            
            # Create QR code instance
            qr = qrcode.QRCode(
                version=1,
                error_correction=qrcode.constants.ERROR_CORRECT_L,
                box_size=10,
                border=4,
            )
            
            # Add data to QR code
            qr_data = {
                'code': self.code,
                'amount': str(self.amount),
                'delivery_boy': self.delivery_boy.email,
                'expires_at': self.expires_at.isoformat()
            }
            qr.add_data(str(qr_data))
            qr.make(fit=True)

            # Create image from QR code
            img = qr.make_image(fill_color="black", back_color="white")
            
            # Save QR code image
            buffer = io.BytesIO()
            img.save(buffer, format='PNG')
            filename = f'delivery_voucher_qr_{self.code}.png'
            self.qr_code.save(filename, ContentFile(buffer.getvalue()), save=False)
            
        super().save(*args, **kwargs)

    class Meta:
        ordering = ['-created_at']

# نموذج QRCodeUsage
class QRCodeUsage(models.Model):
    user = models.ForeignKey(Register, on_delete=models.CASCADE, related_name='qr_code_usages')
    delivery_boy = models.ForeignKey(DeliveryBoy, on_delete=models.CASCADE, related_name='qr_code_usages', null=True, blank=True)
    branch = models.ForeignKey(Branch, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    used_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.email} used QR at {self.branch} for {self.amount}"

# نموذج CustomerVoucher
class CustomerVoucher(models.Model):
    user = models.ForeignKey(Register, on_delete=models.CASCADE, related_name='vouchers')
    code = models.CharField(max_length=20, unique=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    is_used = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    used_branch = models.ForeignKey(Branch, on_delete=models.SET_NULL, null=True, blank=True, related_name='customer_used_vouchers')
    qr_code = models.ImageField(upload_to='customer_vouchers_qr/', null=True, blank=True)

    def __str__(self):
        return f"Voucher {self.code} for {self.user.email}"

    def save(self, *args, **kwargs):
        if not self.expires_at:
            self.expires_at = timezone.now() + timezone.timedelta(hours=48)
        
        # Generate QR code if it doesn't exist
        if not self.qr_code:
            import qrcode
            import io
            from django.core.files.base import ContentFile
            
            # Create QR code instance
            qr = qrcode.QRCode(
                version=1,
                error_correction=qrcode.constants.ERROR_CORRECT_L,
                box_size=10,
                border=4,
            )
            
            # Add data to QR code
            qr_data = {
                'code': self.code,
                'amount': str(self.amount),
                'user': self.user.email,
                'expires_at': self.expires_at.isoformat()
            }
            qr.add_data(str(qr_data))
            qr.make(fit=True)

            # Create image from QR code
            img = qr.make_image(fill_color="black", back_color="white")
            
            # Save QR code image
            buffer = io.BytesIO()
            img.save(buffer, format='PNG')
            filename = f'customer_voucher_qr_{self.code}.png'
            self.qr_code.save(filename, ContentFile(buffer.getvalue()), save=False)
            
        super().save(*args, **kwargs)

    class Meta:
        ordering = ['-created_at']

# نموذج Notification
class Notification(models.Model):
    user = models.ForeignKey(Register, on_delete=models.CASCADE, related_name='notifications')
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)

    def __str__(self):
        return f"Notification for {self.user.email} - {self.message}"

    class Meta:
        ordering = ['-created_at']

# نموذج ItemType
class ItemType(models.Model):
    name = models.CharField(max_length=100)
    co2_per_unit = models.DecimalField(max_digits=5, decimal_places=2, default=0.0)

    def save(self, *args, **kwargs):
        # تعيين قيم CO2 الافتراضية عند إنشاء نوع جديد
        if not self.co2_per_unit or self.co2_per_unit == 0.0:
            if self.name == 'Plastic Bottle':
                self.co2_per_unit = 0.82  # 0.82 كجم CO2 لكل زجاجة بلاستيك
            elif self.name == 'Glass Bottle':
                self.co2_per_unit = 0.50  # 0.50 كجم CO2 لكل زجاجة زجاج
            elif self.name == 'Aluminum Can':
                self.co2_per_unit = 1.09  # 1.09 كجم CO2 لكل علبة ألومنيوم
        super().save(*args, **kwargs)

    def __str__(self):
        return self.name

# نموذج RecycleBag
class RecycleBag(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('assigned', 'Assigned'),
        ('accepted', 'Accepted'),
        ('in_transit', 'In Transit'),
        ('delivered', 'Delivered'),
        ('rejected', 'Rejected'),
        ('canceled', 'Canceled'),
    ]
    user = models.ForeignKey(Register, on_delete=models.CASCADE)
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='pending'
    )
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    rejection_reason = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Bag {self.id} - {self.status}"

# نموذج RecycleBagItem
class RecycleBagItem(models.Model):
    bag = models.ForeignKey(RecycleBag, on_delete=models.CASCADE, related_name='items')
    item_type = models.ForeignKey(ItemType, on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField()
    points = models.PositiveIntegerField()

    def __str__(self):
        return f"{self.quantity} x {self.item_type.name} ({self.points} pts)"

# نموذج Activity
class Activity(models.Model):
    TYPE_CHOICES = [
        ('earn', 'Earn'),
        ('redeem', 'Redeem'),
        ('cancel', 'Cancel'),
        ('delivered', 'Delivered'),
        ('rejected', 'Rejected'),
        ('accepted', 'Accepted'),
    ]
    user = models.ForeignKey(Register, on_delete=models.CASCADE, related_name='activities')
    title = models.CharField(max_length=200)
    points = models.IntegerField()
    co2_saved = models.DecimalField(max_digits=10, decimal_places=2, default=0.0)  # كجم CO2
    type = models.CharField(max_length=50, choices=TYPE_CHOICES)
    date = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.email} - {self.title} - {self.date}"

    class Meta:
        ordering = ['-date']

# نموذج DeliveryAssignment
class DeliveryAssignment(models.Model):
    recycle_bag = models.ForeignKey(RecycleBag, on_delete=models.CASCADE)
    delivery_boy = models.ForeignKey(DeliveryBoy, on_delete=models.CASCADE, null=True, blank=True)
    status = models.CharField(
        max_length=20,
        choices=[
            ('pending', 'Pending'),
            ('accepted', 'Accepted'),
            ('in_transit', 'In Transit'),
            ('delivered', 'Delivered'),
            ('rejected', 'Rejected'),
            ('canceled', 'Canceled'),
        ],
        default='pending'
    )
    rejection_reason = models.TextField(null=True, blank=True)
    assigned_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    discrepancy_report = models.TextField(null=True, blank=True)
    cancel_reason = models.TextField(null=True, blank=True)
    accepted_by = models.ForeignKey(DeliveryBoy, on_delete=models.SET_NULL, null=True, blank=True, related_name='accepted_assignments')
    last_status_update = models.DateTimeField(auto_now=True)
    delivery_boy_phone = models.CharField(max_length=15, null=True, blank=True)
    user_phone = models.CharField(max_length=15, null=True, blank=True)
    user_location = models.TextField(null=True, blank=True)
    delivery_boy_location = models.TextField(null=True, blank=True)
    chat_enabled = models.BooleanField(default=True)
    
    def __str__(self):
        return f"Assignment {self.id} - {self.status}"

    def has_active_assignment(self):
        return self.status in ['accepted', 'in_transit']

    def can_be_accepted(self):
        return self.status == 'pending'

    def can_be_rejected(self):
        return self.status in ['pending', 'accepted', 'in_transit']

    def can_be_canceled(self):
        return self.status in ['accepted', 'in_transit']

    def can_be_delivered(self):
        return self.status == 'in_transit'

    def save(self, *args, **kwargs):
        # Check for existing active assignments for this recycle bag
        if not self.pk:  # If this is a new assignment
            existing = DeliveryAssignment.objects.filter(
                recycle_bag=self.recycle_bag,
                status__in=['pending', 'accepted', 'in_transit']
            ).first()
            
            if existing:
                # If there's an existing active assignment, update it instead of creating a new one
                self.pk = existing.pk
                self._state.adding = False
                
                # Log the update
                logger.info(f"Updating existing assignment {self.pk} for recycle bag {self.recycle_bag.id}")
            else:
                logger.info(f"Creating new assignment for recycle bag {self.recycle_bag.id}")

        super().save(*args, **kwargs)

    class Meta:
        ordering = ['-assigned_at']
        constraints = [
            models.UniqueConstraint(
                fields=['recycle_bag'],
                condition=models.Q(status__in=['pending', 'accepted', 'in_transit']),
                name='unique_active_assignment'
            )
        ]

class ChatMessage(models.Model):
    assignment = models.ForeignKey(DeliveryAssignment, on_delete=models.CASCADE, related_name='messages')
    sender_type = models.CharField(
        max_length=20,
        choices=[
            ('user', 'User'),
            ('delivery_boy', 'Delivery Boy')
        ]
    )
    sender_id = models.CharField(max_length=255)
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)

    def __str__(self):
        return f"Message from {self.sender_type} in Assignment {self.assignment.id}"

    class Meta:
        ordering = ['created_at']