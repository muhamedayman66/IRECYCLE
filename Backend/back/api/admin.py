from django.contrib import admin
from django import forms
from .models import (
    Register, RecycleBag, ItemType, RecycleBagItem, Store, Branch, QRCodeUsage,
    Notification, Activity, DeliveryBoy, DeliveryAssignment,
    DeliveryBoyRating, DeliveryBoyNotification, DeliveryBoyVoucher, CustomerVoucher
)
import logging
from django.utils import timezone

logger = logging.getLogger(__name__)

@admin.register(Register)
class RegisterAdmin(admin.ModelAdmin):
    list_display = ('first_name', 'last_name', 'email', 'points', 'rewards', 'co2_saved', 'items_recycled', 'created_at')
    fields = (
        'first_name', 'last_name', 'gender', 'email', 'password',
        'birth_date', 'phone_number', 'governorate', 'type',
        'points', 'rewards', 'co2_saved', 'items_recycled', 'image'
    )
    search_fields = ['email', 'first_name', 'last_name']
    list_filter = ('governorate', 'type', 'created_at')
    ordering = ('-created_at',)

    def qr_code_url_display(self, obj):
        if obj.qr_code:
            return obj.qr_code.url
        return '-'
    qr_code_url_display.short_description = 'QR Code URL'

# DeliveryBoy Admin
@admin.register(DeliveryBoy)
class DeliveryBoyAdmin(admin.ModelAdmin):
    list_display = ('first_name', 'last_name', 'email', 'points', 'rewards', 'total_orders_delivered', 'average_rating', 'created_at')
    fields = (
        'first_name', 'last_name', 'gender', 'email', 'password',
        'birth_date', 'phone_number', 'governorate', 'type',
        'points', 'rewards', 'total_orders_delivered', 'average_rating', 
        'image', 'is_available'
    )
    search_fields = ['email', 'first_name', 'last_name']
    list_filter = ('governorate', 'type', 'created_at', 'is_available')
    ordering = ('-created_at',)

# ItemType Admin
@admin.register(ItemType)
class ItemTypeAdmin(admin.ModelAdmin):
    list_display = ('name',)
    search_fields = ['name']
    ordering = ('name',)

# RecycleBagItem Inline
class RecycleBagItemInline(admin.TabularInline):
    model = RecycleBagItem
    extra = 1
    autocomplete_fields = ['item_type']

@admin.register(RecycleBag)
class RecycleBagAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'display_items', 'total_points_earned', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('user__email', 'items__item_type__name')
    inlines = [RecycleBagItemInline]
    ordering = ('-created_at',)

    def display_items(self, obj):
        """Display the items in the recycle bag."""
        return ", ".join([f"{item.quantity} {item.item_type.name}" for item in obj.items.all()])
    display_items.short_description = 'Items'

    def total_points_earned(self, obj):
        """Calculate total points earned from all items."""
        return sum(item.points for item in obj.items.all())
    total_points_earned.short_description = 'Total Points'

    def save_model(self, request, obj, form, change):
        """Override save_model to assign the recycle bag to delivery boys after saving."""
        super().save_model(request, obj, form, change)  # Save the RecycleBag first
        
        if obj.status == 'pending':  # If status is pending
            logger.info(f"Processing pending bag {obj.id} for user in {obj.user.governorate}")
            
            # Find delivery boys in the same governorate
            delivery_boys = DeliveryBoy.objects.filter(
                governorate=obj.user.governorate,
                is_available=True
            )
            logger.info(f"Found {delivery_boys.count()} available delivery boys in {obj.user.governorate}")
            
            if delivery_boys.exists():
                # Select the delivery boy with the least number of active assignments
                delivery_boy = min(
                    delivery_boys,
                    key=lambda db: DeliveryAssignment.objects.filter(
                        delivery_boy=db,
                        status__in=['pending', 'accepted', 'in_transit']
                    ).count()
                )
                
                # Check for existing active assignment
                existing_assignment = DeliveryAssignment.objects.filter(
                    recycle_bag=obj,
                    status__in=['pending', 'accepted', 'in_transit']
                ).first()
                
                if existing_assignment:
                    # Update existing assignment
                    existing_assignment.delivery_boy = delivery_boy
                    existing_assignment.status = 'pending'
                    existing_assignment.save()
                    assignment = existing_assignment
                else:
                    # Create a new delivery assignment
                    assignment = DeliveryAssignment.objects.create(
                        recycle_bag=obj,
                        delivery_boy=delivery_boy,
                        status='pending'
                    )
                
                # Create notification for delivery boy
                DeliveryBoyNotification.objects.create(
                    delivery_boy=delivery_boy,
                    message=f"New order #{obj.id} available in your area. Accept or decline."
                )
                
                logger.info(f"Successfully assigned bag {obj.id} to {delivery_boy.email}")
                self.message_user(request, f"Recycle bag {obj.id} was successfully assigned to {delivery_boy.email}")
            else:
                logger.warning(f"No available delivery boys found in {obj.user.governorate}")
                self.message_user(
                    request, 
                    f"No delivery boys found in {obj.user.governorate} to assign recycle bag {obj.id}.", 
                    level='warning'
                )

    def get_queryset(self, request):
        """Override get_queryset to ensure all records are fetched."""
        queryset = super().get_queryset(request)
        return queryset.all()  # جلب جميع السجلات بدلاً من تصفية افتراضية

# Branch Inline
class BranchInline(admin.TabularInline):
    model = Branch
    extra = 1

# Store Admin
@admin.register(Store)
class StoreAdmin(admin.ModelAdmin):
    list_display = ('name', 'phone_number', 'category', 'created_at')
    inlines = [BranchInline]
    search_fields = ['name', 'phone_number']
    list_filter = ('category', 'created_at')
    ordering = ('-created_at',)

# Branch Admin
@admin.register(Branch)
class BranchAdmin(admin.ModelAdmin):
    list_display = ('name', 'store', 'governorate', 'phone_number', 'created_at')
    search_fields = ['name', 'store__name', 'phone_number']
    list_filter = ('governorate', 'created_at')
    ordering = ('-created_at',)

# Notification Admin
@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('user', 'message', 'is_read', 'created_at')
    list_filter = ('is_read', 'created_at')
    search_fields = ('user__email', 'message')
    ordering = ('-created_at',)
    actions = ['mark_as_read', 'mark_as_unread']

    def mark_as_read(self, request, queryset):
        """Mark selected notifications as read."""
        count = queryset.update(is_read=True)
        self.message_user(request, f"Marked {count} notifications as read.")
    mark_as_read.short_description = "Mark Notifications as Read"

    def mark_as_unread(self, request, queryset):
        """Mark selected notifications as unread."""
        count = queryset.update(is_read=False)
        self.message_user(request, f"Marked {count} notifications as unread.")
    mark_as_unread.short_description = "Mark Notifications as Unread"

# QRCodeUsage Form
class QRCodeUsageForm(forms.ModelForm):
    class Meta:
        model = QRCodeUsage
        fields = '__all__'

    def clean(self):
        """Validate QR code usage."""
        cleaned_data = super().clean()
        user = cleaned_data.get('user')
        amount = cleaned_data.get('amount')

        if user:
            # Check if user has an active voucher
            active_voucher = CustomerVoucher.objects.filter(
                user=user,
                is_used=False,
                expires_at__gt=timezone.now()
            ).first()

            if not active_voucher:
                raise forms.ValidationError(
                    f"User {user.email} does not have an active voucher."
                )

            if amount != active_voucher.amount:
                raise forms.ValidationError(
                    f"The amount ({amount}) does not match the user's voucher amount ({active_voucher.amount})."
                )

            if active_voucher.expires_at < timezone.now():
                active_voucher.is_used = True
                active_voucher.save()
                raise forms.ValidationError(
                    f"The voucher for user {user.email} has expired."
                )

        return cleaned_data

# QRCodeUsage Admin
@admin.register(QRCodeUsage)
class QRCodeUsageAdmin(admin.ModelAdmin):
    form = QRCodeUsageForm
    list_display = ('user', 'delivery_boy', 'branch', 'amount', 'used_at')
    list_filter = ('used_at',)
    search_fields = ('user__email', 'delivery_boy__email', 'branch__name')
    autocomplete_fields = ['user', 'delivery_boy', 'branch']
    actions = ['delete_vouchers_from_branch']
    ordering = ('-used_at',)

    def save_model(self, request, obj, form, change):
        """Handle voucher usage and update related records."""
        super().save_model(request, obj, form, change)

        # Find and update the active voucher
        active_voucher = CustomerVoucher.objects.filter(
            user=obj.user,
            is_used=False,
            expires_at__gt=timezone.now()
        ).first()

        if active_voucher:
            active_voucher.is_used = True
            active_voucher.used_branch = obj.branch
            active_voucher.save()

        message = f"You used a voucher of {obj.amount} EGP at {obj.branch} on {obj.used_at.strftime('%Y-%m-%d %I:%M %p')}"
        Notification.objects.create(user=obj.user, message=message)

    def delete_vouchers_from_branch(self, request, queryset):
        """Delete vouchers associated with a specific branch."""
        branch = queryset.first().branch
        vouchers = CustomerVoucher.objects.filter(used_branch=branch)
        count = vouchers.count()
        vouchers.update(is_used=True)
        self.message_user(request, f"Marked {count} vouchers as used from branch {branch.name}")
    delete_vouchers_from_branch.short_description = "Delete Vouchers from Branch"

# CustomerVoucher Admin
@admin.register(CustomerVoucher)
class CustomerVoucherAdmin(admin.ModelAdmin):
    list_display = ('code', 'user_name', 'user_email', 'amount', 'is_used', 'status', 'created_at', 'expires_at', 'remaining_time', 'used_branch_name', 'store_name', 'qr_code_display')
    fields = ('user', 'code', 'amount', 'is_used', 'created_at', 'expires_at', 'used_branch', 'qr_code')
    readonly_fields = ('created_at', 'qr_code')
    search_fields = ('user__email', 'user__first_name', 'user__last_name', 'code', 'used_branch__name', 'used_branch__store__name')
    list_filter = ('is_used', 'created_at', 'expires_at', 'used_branch__store__name')
    ordering = ('-created_at',)
    actions = ['mark_as_used', 'mark_as_unused', 'extend_expiry']
    list_per_page = 20

    def user_name(self, obj):
        return f"{obj.user.first_name} {obj.user.last_name}"
    user_name.short_description = 'User Name'
    user_name.admin_order_field = 'user__first_name'

    def user_email(self, obj):
        return obj.user.email
    user_email.short_description = 'Email'
    user_email.admin_order_field = 'user__email'

    def used_branch_name(self, obj):
        if obj.used_branch:
            return obj.used_branch.name
        return '-'
    used_branch_name.short_description = 'Used at Branch'
    used_branch_name.admin_order_field = 'used_branch__name'

    def store_name(self, obj):
        if obj.used_branch:
            return obj.used_branch.store.name
        return '-'
    store_name.short_description = 'Store'
    store_name.admin_order_field = 'used_branch__store__name'

    def status(self, obj):
        if obj.is_used:
            return 'Used'
        if obj.expires_at < timezone.now():
            return 'Expired'
        return 'Active'
    status.short_description = 'Status'

    def remaining_time(self, obj):
        if obj.is_used:
            return 'Used'
        now = timezone.now()
        if obj.expires_at < now:
            return 'Expired'
        diff = obj.expires_at - now
        days = diff.days
        hours = diff.seconds // 3600
        minutes = (diff.seconds % 3600) // 60
        if days > 0:
            return f'{days}d {hours}h'
        return f'{hours}h {minutes}m'
    remaining_time.short_description = 'Time Left'

    def mark_as_used(self, request, queryset):
        """Mark selected vouchers as used."""
        count = queryset.update(is_used=True)
        self.message_user(request, f"Marked {count} vouchers as used.")
    mark_as_used.short_description = "Mark Vouchers as Used"

    def mark_as_unused(self, request, queryset):
        """Mark selected vouchers as unused."""
        count = queryset.update(is_used=False)
        self.message_user(request, f"Marked {count} vouchers as unused.")
    mark_as_unused.short_description = "Mark Vouchers as Unused"

    def extend_expiry(self, request, queryset):
        """Extend expiry of selected vouchers by 24 hours."""
        for voucher in queryset:
            voucher.expires_at = voucher.expires_at + timezone.timedelta(hours=24)
            voucher.save()
        count = queryset.count()
        self.message_user(request, f"Extended expiry for {count} vouchers by 24 hours.")
    extend_expiry.short_description = "Extend Expiry by 24 Hours"

    def qr_code_display(self, obj):
        if obj.qr_code:
            return f'<img src="{obj.qr_code.url}" width="50" height="50" />'
        return '-'
    qr_code_display.short_description = 'QR Code'
    qr_code_display.allow_tags = True

    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user', 'used_branch', 'used_branch__store')

# Activity Admin
@admin.register(Activity)
class ActivityAdmin(admin.ModelAdmin):
    list_display = ('user', 'title', 'points', 'type', 'date')
    list_filter = ('type', 'date')
    search_fields = ('user__email', 'title')
    ordering = ('-date',)

@admin.register(DeliveryAssignment)
class DeliveryAssignmentAdmin(admin.ModelAdmin):
    list_display = ('recycle_bag', 'accepted_by', 'status', 'assigned_at', 'updated_at')
    list_filter = ('status', 'assigned_at', 'accepted_by__governorate')
    search_fields = ('recycle_bag__id', 'accepted_by__email')
    ordering = ('-assigned_at',)
    fields = ('recycle_bag', 'accepted_by', 'status', 'discrepancy_report', 'cancel_reason')
    readonly_fields = ('assigned_at', 'updated_at')
    actions = ['reassign_orders']

    def get_queryset(self, request):
        """Override get_queryset to ensure only unique assignments are shown."""
        queryset = super().get_queryset(request)
        # Get the latest assignment for each recycle bag
        latest_assignments = {}
        for assignment in queryset:
            bag_id = assignment.recycle_bag_id
            if bag_id not in latest_assignments or assignment.assigned_at > latest_assignments[bag_id].assigned_at:
                latest_assignments[bag_id] = assignment
        return queryset.filter(id__in=[a.id for a in latest_assignments.values()])

    def reassign_orders(self, request, queryset):
        """إعادة تعيين الطلبات المحددة لدليفري بويز آخرين"""
        from .views import assign_order_to_delivery_boy
        count = 0
        for assignment in queryset.filter(status__in=['pending', 'rejected']):
            assignment.status = 'canceled'
            assignment.save()
            assign_order_to_delivery_boy(assignment.recycle_bag)
            count += 1
        self.message_user(request, f"Reassigned {count} orders.")
    reassign_orders.short_description = "Reassign Orders"

# DeliveryBoyRating Admin
@admin.register(DeliveryBoyRating)
class DeliveryBoyRatingAdmin(admin.ModelAdmin):
    list_display = ('recycle_bag', 'delivery_boy', 'user', 'user_rating', 'created_at')
    list_filter = ('user_rating', 'created_at')
    search_fields = ('recycle_bag__id', 'delivery_boy__email', 'user__email')
    ordering = ('-created_at',)

# DeliveryBoyNotification Admin
@admin.register(DeliveryBoyNotification)
class DeliveryBoyNotificationAdmin(admin.ModelAdmin):
    list_display = ('delivery_boy', 'message', 'is_read', 'created_at')
    list_filter = ('is_read', 'created_at')
    search_fields = ('delivery_boy__email', 'message')
    ordering = ('-created_at',)
    actions = ['mark_as_read', 'mark_as_unread']

    def mark_as_read(self, request, queryset):
        """Mark selected delivery boy notifications as read."""
        count = queryset.update(is_read=True)
        self.message_user(request, f"Marked {count} notifications as read.")
    mark_as_read.short_description = "Mark Notifications as Read"

    def mark_as_unread(self, request, queryset):
        """Mark selected delivery boy notifications as unread."""
        count = queryset.update(is_read=False)
        self.message_user(request, f"Marked {count} notifications as unread.")
    mark_as_unread.short_description = "Mark Notifications as Unread"

# DeliveryBoyVoucher Admin
@admin.register(DeliveryBoyVoucher)
class DeliveryBoyVoucherAdmin(admin.ModelAdmin):
    list_display = ('code', 'delivery_boy_name', 'delivery_boy_email', 'amount', 'is_used', 'status', 'created_at', 'expires_at', 'remaining_time', 'used_branch_name', 'store_name', 'qr_code_display')
    fields = ('delivery_boy', 'code', 'amount', 'is_used', 'created_at', 'expires_at', 'used_branch', 'qr_code')
    readonly_fields = ('created_at', 'qr_code')
    search_fields = ('delivery_boy__email', 'delivery_boy__first_name', 'delivery_boy__last_name', 'code', 'used_branch__name', 'used_branch__store__name')
    list_filter = ('is_used', 'created_at', 'expires_at', 'used_branch__store__name')
    ordering = ('-created_at',)
    actions = ['mark_as_used', 'mark_as_unused', 'extend_expiry']
    list_per_page = 20

    def delivery_boy_name(self, obj):
        return f"{obj.delivery_boy.first_name} {obj.delivery_boy.last_name}"
    delivery_boy_name.short_description = 'Delivery Boy Name'
    delivery_boy_name.admin_order_field = 'delivery_boy__first_name'

    def delivery_boy_email(self, obj):
        return obj.delivery_boy.email
    delivery_boy_email.short_description = 'Email'
    delivery_boy_email.admin_order_field = 'delivery_boy__email'

    def used_branch_name(self, obj):
        if obj.used_branch:
            return obj.used_branch.name
        return '-'
    used_branch_name.short_description = 'Used at Branch'
    used_branch_name.admin_order_field = 'used_branch__name'

    def store_name(self, obj):
        if obj.used_branch:
            return obj.used_branch.store.name
        return '-'
    store_name.short_description = 'Store'
    store_name.admin_order_field = 'used_branch__store__name'

    def status(self, obj):
        if obj.is_used:
            return 'Used'
        if obj.expires_at < timezone.now():
            return 'Expired'
        return 'Active'
    status.short_description = 'Status'

    def remaining_time(self, obj):
        if obj.is_used:
            return 'Used'
        now = timezone.now()
        if obj.expires_at < now:
            return 'Expired'
        diff = obj.expires_at - now
        days = diff.days
        hours = diff.seconds // 3600
        minutes = (diff.seconds % 3600) // 60
        if days > 0:
            return f'{days}d {hours}h'
        return f'{hours}h {minutes}m'
    remaining_time.short_description = 'Time Left'

    def mark_as_used(self, request, queryset):
        """Mark selected vouchers as used."""
        count = queryset.update(is_used=True)
        self.message_user(request, f"Marked {count} vouchers as used.")
    mark_as_used.short_description = "Mark Vouchers as Used"

    def mark_as_unused(self, request, queryset):
        """Mark selected vouchers as unused."""
        count = queryset.update(is_used=False)
        self.message_user(request, f"Marked {count} vouchers as unused.")
    mark_as_unused.short_description = "Mark Vouchers as Unused"

    def extend_expiry(self, request, queryset):
        """Extend expiry of selected vouchers by 24 hours."""
        for voucher in queryset:
            voucher.expires_at = voucher.expires_at + timezone.timedelta(hours=24)
            voucher.save()
        count = queryset.count()
        self.message_user(request, f"Extended expiry for {count} vouchers by 24 hours.")
    extend_expiry.short_description = "Extend Expiry by 24 Hours"

    def qr_code_display(self, obj):
        if obj.qr_code:
            return f'<img src="{obj.qr_code.url}" width="50" height="50" />'
        return '-'
    qr_code_display.short_description = 'QR Code'
    qr_code_display.allow_tags = True

    def get_queryset(self, request):
        return super().get_queryset(request).select_related('delivery_boy', 'used_branch', 'used_branch__store')