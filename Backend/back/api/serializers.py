from rest_framework import serializers
from django.contrib.auth.models import User
from django.utils import timezone
from .models import RecycleBagItem, RecycleBag, Register, Store, Branch, QRCodeUsage, Notification, Activity, DeliveryBoy, DeliveryAssignment, DeliveryBoyRating, DeliveryBoyNotification, DeliveryBoyVoucher, CustomerVoucher

class UserRegisterSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['username', 'email', 'password']
        extra_kwargs = {
            'password': {'write_only': True}
        }

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'], 
            password=validated_data['password']
        )
        user.profile.balance = 0
        user.profile.voucher = ''
        user.profile.save()
        return user

class RegisterSerializer(serializers.ModelSerializer):
    qr_code_url = serializers.SerializerMethodField()

    class Meta:
        model = Register
        fields = '__all__'

    def get_qr_code_url(self, obj):
        # Get the latest, active (not used, not expired) voucher with a QR code
        latest_voucher = obj.vouchers.filter(
            qr_code__isnull=False,  # Ensure qr_code field is not DB null
            is_used=False,
            expires_at__gt=timezone.now()
        ).exclude(
            qr_code=''  # Ensure qr_code field is not an empty string
        ).order_by('-created_at').first()

        if latest_voucher: # The query ensures latest_voucher.qr_code exists if latest_voucher is found
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(latest_voucher.qr_code.url)
            return latest_voucher.qr_code.url
        return None

class DeliveryBoySerializer(serializers.ModelSerializer):
    class Meta:
        model = DeliveryBoy
        fields = ['id', 'first_name', 'last_name', 'gender', 'email', 'password',
                 'birth_date', 'phone_number', 'governorate', 'type', 'points',
                 'rewards', 'total_orders_delivered', 'average_rating', 'image',
                 'last_activity', 'created_at', 'is_available']

class RecycleItemSerializer(serializers.ModelSerializer):
    item_type = serializers.CharField(source='item_type.name')
    co2_per_unit = serializers.DecimalField(max_digits=5, decimal_places=2, source='item_type.co2_per_unit', read_only=True)

    class Meta:
        model = RecycleBagItem
        fields = ['item_type', 'quantity', 'points', 'co2_per_unit']

class RecycleBagSerializer(serializers.ModelSerializer):
    items = RecycleItemSerializer(many=True, read_only=True)
    user = serializers.CharField(source='user.email')
    user_details = serializers.SerializerMethodField()
    status = serializers.CharField()
    latitude = serializers.CharField(allow_null=True)
    longitude = serializers.CharField(allow_null=True)
    delivery_boy = serializers.SerializerMethodField()
    accepted_by = serializers.SerializerMethodField()
    total_points = serializers.SerializerMethodField()
    rewards = serializers.SerializerMethodField()
    co2_saved = serializers.SerializerMethodField()

    class Meta:
        model = RecycleBag
        fields = ['id', 'user', 'user_details', 'items', 'status', 'latitude', 'longitude', 
                  'created_at', 'delivery_boy', 'accepted_by', 'total_points', 'rewards', 'co2_saved']

    def get_user_details(self, obj):
        return {
            'first_name': obj.user.first_name,
            'last_name': obj.user.last_name,
            'phone_number': obj.user.phone_number,
            'governorate': obj.user.governorate,
            'address': obj.user.address,
            'email': obj.user.email  # Added customer email
        }

    def get_delivery_boy(self, obj):
        assignment = DeliveryAssignment.objects.filter(
            recycle_bag=obj, status__in=['accepted', 'in_transit', 'delivered']
        ).first()
        if assignment and assignment.delivery_boy:
            return {
                'first_name': assignment.delivery_boy.first_name,
                'last_name': assignment.delivery_boy.last_name,
                'phone_number': assignment.delivery_boy.phone_number,
                'email': assignment.delivery_boy.email,
                'rating': str(assignment.delivery_boy.average_rating)
            }
        return None
    
    def get_accepted_by(self, obj):
        assignment = DeliveryAssignment.objects.filter(recycle_bag=obj, status='accepted').first()
        if assignment and assignment.accepted_by:
            return {
                'first_name': assignment.accepted_by.first_name,
                'last_name': assignment.accepted_by.last_name,
                'phone_number': assignment.accepted_by.phone_number
            }
        return None

    def get_total_points(self, obj):
        return sum(item.points for item in obj.items.all())

    def get_rewards(self, obj):
        total_points = sum(item.points for item in obj.items.all())
        return int(total_points / 20)

    def get_co2_saved(self, obj):
        return sum(item.quantity * item.item_type.co2_per_unit for item in obj.items.all())

class BranchSerializer(serializers.ModelSerializer):
    class Meta:
        model = Branch
        fields = ['id', 'name', 'latitude', 'longitude', 'phone_number', 'governorate']

class StoreSerializer(serializers.ModelSerializer):
    branches = BranchSerializer(many=True, read_only=True)
    class Meta:
        model = Store
        fields = ['id', 'name', 'phone_number', 'category', 'branches']

class QRCodeUsageSerializer(serializers.ModelSerializer):
    user = RegisterSerializer(read_only=True)
    delivery_boy = DeliveryBoySerializer(read_only=True)
    branch = BranchSerializer(read_only=True)

    class Meta:
        model = QRCodeUsage
        fields = ['id', 'user', 'delivery_boy', 'branch', 'amount', 'used_at']

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'message', 'created_at', 'is_read']

class ActivitySerializer(serializers.ModelSerializer):
    voucher_amount = serializers.SerializerMethodField()

    class Meta:
        model = Activity
        fields = ['id', 'title', 'points', 'co2_saved', 'type', 'date', 'voucher_amount']

    def get_voucher_amount(self, obj):
        if obj.type == 'redeem':
            return abs(obj.points) / 20
        return None

class DeliveryAssignmentSerializer(serializers.ModelSerializer):
    recycle_bag = RecycleBagSerializer(read_only=True)
    delivery_boy = serializers.SerializerMethodField()

    class Meta:
        model = DeliveryAssignment
        fields = ['id', 'recycle_bag', 'delivery_boy', 'status', 'assigned_at', 'updated_at', 'discrepancy_report']

    def get_delivery_boy(self, obj):
        if obj.delivery_boy:
            return {
                'id': obj.delivery_boy.id,
                'email': obj.delivery_boy.email,
                'first_name': obj.delivery_boy.first_name,
                'last_name': obj.delivery_boy.last_name,
                'phone_number': obj.delivery_boy.phone_number,
                'governorate': obj.delivery_boy.governorate
            }
        return None

class DeliveryBoyRatingSerializer(serializers.ModelSerializer):
    user = RegisterSerializer(read_only=True)
    delivery_boy = DeliveryBoySerializer(read_only=True)
    recycle_bag = RecycleBagSerializer(read_only=True)

    class Meta:
        model = DeliveryBoyRating
        fields = ['id', 'recycle_bag', 'delivery_boy', 'user', 'user_rating', 'user_comment', 'created_at']

class DeliveryBoyNotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeliveryBoyNotification
        fields = ['id', 'message', 'created_at', 'is_read']

class DeliveryBoyVoucherSerializer(serializers.ModelSerializer):
    qr_code_url = serializers.SerializerMethodField()

    class Meta:
        model = DeliveryBoyVoucher
        fields = ['id', 'delivery_boy', 'code', 'amount', 'is_used', 'created_at', 'expires_at', 'used_branch', 'qr_code_url']

    def get_qr_code_url(self, obj):
        if obj.qr_code and hasattr(obj.qr_code, 'url'):
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.qr_code.url)
            return obj.qr_code.url  # Fallback if no request in context (e.g. shell)
        return None

class CustomerVoucherSerializer(serializers.ModelSerializer):
    user = RegisterSerializer(read_only=True)
    used_branch = BranchSerializer(read_only=True)
    qr_code_url = serializers.SerializerMethodField() # Added

    class Meta:
        model = CustomerVoucher
        fields = ['id', 'user', 'code', 'amount', 'is_used', 'created_at', 'expires_at', 'used_branch', 'qr_code', 'qr_code_url'] # Added qr_code_url

    def get_qr_code_url(self, obj): # Added method
        if obj.qr_code and hasattr(obj.qr_code, 'url'):
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.qr_code.url)
            return obj.qr_code.url
        return None