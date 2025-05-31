from django.urls import path
from . import views

urlpatterns = [
    path('', views.getRoute, name='routes'),
    
    # Register endpoints
    path('registers/', views.getRegisters, name='registers'),
    path('registers/<int:pk>/', views.getRegister, name='register'),
    path('registers/create/', views.createRegister, name='create-register'),
    path('registers/<int:pk>/update/', views.updateRegister, name='update-register'),
    path('registers/<int:pk>/delete/', views.deleteRegister, name='delete-register'),
    path('registers/update_password/', views.updatePassword, name='update-password'),
    path('registers/update_rewards/', views.updatePointsAndRewards, name='update-rewards'),
    
    # Delivery Boy endpoints
    path('delivery_boys/', views.getDeliveryBoys, name='delivery-boys'),
    path('delivery_boys/<int:pk>/', views.getDeliveryBoy, name='delivery-boy'),
    path('delivery_boys/create/', views.createDeliveryBoy, name='create-delivery-boy'),
    path('delivery_boys/<int:pk>/update/', views.updateDeliveryBoy, name='update-delivery-boy'),
    path('delivery_boys/<int:pk>/delete/', views.deleteDeliveryBoy, name='delete-delivery-boy'),
    path('delivery_boys/<int:delivery_boy_id>/update_stats/', views.update_delivery_boy_stats, name='update_delivery_boy_stats'),
    
    # Delivery Boy order management
    path('delivery/available_orders/<str:email>/', views.get_available_orders, name='available-orders'),
    path('delivery/accept_order/<int:assignment_id>/', views.accept_order, name='accept_order'),
    path('delivery/reject_order/<int:assignment_id>/', views.reject_order, name='reject_order'),
    path('delivery/verify_order/<int:assignment_id>/', views.verify_order, name='verify-order'),
    path('assignments/<int:assignment_id>/start_delivery/', views.start_delivery_process, name='start_delivery_process'), # New URL
    path('assignments/<int:assignment_id>/complete/', views.complete_order, name='complete_order'),
    path('delivery/cancel_order/<int:assignment_id>/', views.cancel_order, name='cancel_order'),
    path('delivery/history/<str:email>/', views.get_delivery_history, name='delivery-history'),
    path('delivery/rate_order/<int:assignment_id>/', views.rate_order, name='rate-order'),
    path('delivery/dashboard/<str:email>/', views.get_delivery_dashboard, name='delivery-dashboard'),
    path('delivery/notifications/<str:email>/', views.get_delivery_notifications, name='delivery-notifications'),
    path('delivery/notifications/<int:notification_id>/mark_as_read/', views.mark_delivery_notification_as_read, name='mark-delivery-notification-read'),
    path('delivery/redeem_points/', views.redeem_delivery_points, name='redeem-delivery-points'),
    
    # Store and QR code endpoints
    path('stores/', views.get_stores, name='stores'),
    path('generate_qr_code_for_user/', views.generate_qr_code_for_user, name='generate-qr-code-for-user'),
    path('use_qr_code/', views.use_qr_code, name='use-qr-code'),
    path('qr_usage_history/<str:email>/', views.qr_usage_history, name='qr-usage-history'),
    
    # Notification and activity endpoints
    path('notifications/<str:email>/', views.get_notifications, name='notifications'),
    path('notifications/<int:notification_id>/mark_as_read/', views.mark_notification_as_read, name='mark-notification-read'),
    path('notifications/<str:email>/clear/', views.clear_notifications, name='clear-notifications'),
    path('activities/<str:email>/', views.get_activities, name='activities'),
    path('activities/<str:email>/add/', views.add_activities, name='add-activities'),
    
    # User balance and voucher endpoints
    path('user_balance/<str:email>/', views.get_user_balance, name='user-balance'),
    path('check_voucher_status/<str:email>/', views.check_voucher_status, name='check-voucher-status'),
    
    # Recycle bag endpoints
    path('recycle_bags/<int:bag_id>/cancel/', views.cancel_bag, name='cancel-bag'),
    path('place_order/', views.place_order, name='place-order'),
    path('create_pending_bag/', views.create_pending_bag, name='create-pending-bag'),
    path('get_pending_bags/<str:email>/', views.get_pending_bags, name='get-pending-bags'),
    path('get_all_bags/<str:email>/', views.get_all_bags, name='get-all-bags'),
    path('confirm_order/', views.confirm_order, name='confirm-order'),
    path('user_orders/<str:email>/', views.user_orders, name='user-orders'),
    path('update_order_status/<int:bag_id>/', views.update_order_status, name='update-order-status'),
    path('total_recycled_items/<str:email>/', views.get_total_recycled_items, name='get_total_recycled_items'),
    
    # Profile endpoints
    path('get_user_profile/', views.get_user_profile, name='get-user-profile'),
    path('update_profile/', views.updateProfile, name='update-profile'),
    
    # Voucher endpoints
    path('delivery-boy/voucher/generate/<str:email>/', views.generate_delivery_boy_voucher, name='generate_delivery_boy_voucher'),
    path('delivery-boy/voucher/list/<str:email>/', views.get_delivery_boy_vouchers, name='get_delivery_boy_vouchers'),
    path('delivery-boy/voucher/use/<str:voucher_code>/', views.use_delivery_boy_voucher, name='use_delivery_boy_voucher'),
    path('delivery-boy/voucher/status/<str:email>/', views.check_delivery_boy_voucher_status, name='check_delivery_boy_voucher_status'),
    
    # New assignment endpoints
    path('orders/<int:order_id>/assignment/', views.get_order_assignment, name='get_order_assignment'),
    path('assignments/create/', views.create_assignment, name='create_assignment'),
    path('assignments/<int:assignment_id>/accept/', views.accept_order, name='accept_assignment'),
    
    # Rating endpoints
    path('orders/rate/<int:assignment_id>/', views.rate_order, name='rate_order'),
    path('orders/latest/<str:email>/', views.get_latest_order, name='get_latest_order'),
    path('orders/available/<str:email>/', views.get_available_user_orders, name='get_available_user_orders'),
    path('orders/status/<str:email>/', views.get_user_order_status, name='get_user_order_status'),
    
    # Chat endpoints
    path('chat/send_message/<int:assignment_id>/', views.send_chat_message, name='send_chat_message'),
    path('chat/get_messages/<int:assignment_id>/', views.get_chat_messages, name='get_chat_messages'),
]
