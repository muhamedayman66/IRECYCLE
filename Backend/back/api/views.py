from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.utils import timezone
from .models import Register, RecycleBag, RecycleBagItem, ItemType, Store, Branch, QRCodeUsage, Notification, Activity, DeliveryBoy, DeliveryAssignment, DeliveryBoyRating, DeliveryBoyNotification, DeliveryBoyVoucher, ChatMessage, CustomerVoucher
from .serializers import RegisterSerializer, RecycleBagSerializer, StoreSerializer, BranchSerializer, QRCodeUsageSerializer, NotificationSerializer, ActivitySerializer, DeliveryBoySerializer, DeliveryAssignmentSerializer, DeliveryBoyRatingSerializer, DeliveryBoyNotificationSerializer, DeliveryBoyVoucherSerializer, CustomerVoucherSerializer
from django.db.models import Sum, Count, Avg, Q, F # Added F
from django.db import transaction
from django.shortcuts import get_object_or_404
import random
import string
import logging
import json
from decimal import Decimal, InvalidOperation
from datetime import datetime, timedelta
from django.http import JsonResponse

logger = logging.getLogger(__name__)

@api_view(['GET'])
def getRoute(request):
    routes = [
        {'Endpoint': '/registers/', 'method': 'GET', 'description': 'Returns all registers'},
        {'Endpoint': '/registers/<int:pk>/', 'method': 'GET', 'description': 'Returns a single register object'},
        {'Endpoint': '/registers/create/', 'method': 'POST', 'description': 'Create new register'},
        {'Endpoint': '/registers/<int:pk>/update/', 'method': 'PUT', 'description': 'Update a register'},
        {'Endpoint': '/registers/<int:pk>/delete/', 'method': 'DELETE', 'description': 'Delete a register'},
        {'Endpoint': '/registers/update_password/', 'method': 'PUT', 'description': 'Update password'},
        {'Endpoint': '/registers/update_rewards/', 'method': 'PUT', 'description': 'Update points and rewards'},
        {'Endpoint': '/stores/', 'method': 'GET', 'description': 'Returns all stores with branches'},
        {'Endpoint': '/use_qr_code/', 'method': 'POST', 'description': 'Record QR code usage'},
        {'Endpoint': '/qr_usage_history/<str:email>/', 'method': 'GET', 'description': 'Returns QR code usage history for a user'},
        {'Endpoint': '/notifications/<str:email>/', 'method': 'GET', 'description': 'Returns notifications for a user'},
        {'Endpoint': '/notifications/<int:notification_id>/mark_as_read/', 'method': 'POST', 'description': 'Mark a notification as read'},
        {'Endpoint': '/notifications/<str:email>/clear/', 'method': 'DELETE', 'description': 'Clear all notifications for a user'},
        {'Endpoint': '/activities/<str:email>/', 'method': 'GET', 'description': 'Returns activities for a user'},
        {'Endpoint': '/activities/<str:email>/add/', 'method': 'POST', 'description': 'Add activities for a user'},
        {'Endpoint': '/user_balance/<str:email>/', 'method': 'GET', 'description': 'Returns user points and rewards'},
        {'Endpoint': '/check_voucher_status/<str:email>/', 'method': 'GET', 'description': 'Check if user has an active voucher'},
        {'Endpoint': '/recycle_bags/<int:bag_id>/cancel/', 'method': 'POST', 'description': 'Cancel a pending recycling bag'},
        {'Endpoint': '/delivery_boys/', 'method': 'GET', 'description': 'Returns all delivery boys'},
        {'Endpoint': '/delivery_boys/<int:pk>/', 'method': 'GET', 'description': 'Returns a single delivery boy'},
        {'Endpoint': '/delivery_boys/create/', 'method': 'POST', 'description': 'Create new delivery boy'},
        {'Endpoint': '/delivery_boys/<int:pk>/update/', 'method': 'PUT', 'description': 'Update a delivery boy'},
        {'Endpoint': '/delivery_boys/<int:pk>/delete/', 'method': 'DELETE', 'description': 'Delete a delivery boy'},
        {'Endpoint': '/delivery/available_orders/<str:email>/', 'method': 'GET', 'description': 'Returns available orders for a delivery boy'},
        {'Endpoint': '/delivery/accept_order/<int:assignment_id>/', 'method': 'POST', 'description': 'Accept an order'},
        {'Endpoint': '/delivery/reject_order/<int:assignment_id>/', 'method': 'POST', 'description': 'Reject an order'},
        {'Endpoint': '/delivery/verify_order/<int:assignment_id>/', 'method': 'POST', 'description': 'Verify order contents'},
        {'Endpoint': '/delivery/complete_order/<int:assignment_id>/', 'method': 'POST', 'description': 'Mark order as delivered'},
        {'Endpoint': '/delivery/history/<str:email>/', 'method': 'GET', 'description': 'Returns delivery boy order history'},
        {'Endpoint': '/delivery/rate_order/<int:assignment_id>/', 'method': 'POST', 'description': 'Rate an order'},
        {'Endpoint': '/delivery/dashboard/<str:email>/', 'method': 'GET', 'description': 'Returns delivery boy dashboard'},
        {'Endpoint': '/delivery/notifications/<str:email>/', 'method': 'GET', 'description': 'Returns delivery boy notifications'},
        {'Endpoint': '/delivery/notifications/<int:notification_id>/mark_as_read/', 'method': 'POST', 'description': 'Mark a delivery boy notification as read'},
        {'Endpoint': '/chat/send_message/<int:assignment_id>/', 'method': 'POST', 'description': 'Send a chat message'},
        {'Endpoint': '/chat/get_messages/<int:assignment_id>/', 'method': 'GET', 'description': 'Get chat messages'},
    ]
    return Response(routes)

# دوال Register
@api_view(['GET'])
def getRegisters(request):
    registers = Register.objects.all()
    serializer = RegisterSerializer(registers, many=True, context={'request': request})
    return Response(serializer.data)

@api_view(['GET'])
def getRegister(request, pk):
    try:
        register = Register.objects.get(id=pk)
        serializer = RegisterSerializer(register, many=False, context={'request': request})
        return Response(serializer.data)
    except Register.DoesNotExist:
        return Response({'error': 'Register not found'}, status=404)

@api_view(['POST'])
def createRegister(request):
    serializer = RegisterSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        user = serializer.save()
        user.balance = 0.00
        user.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=400)

@api_view(['PUT'])
def updateRegister(request, pk):
    try:
        register = Register.objects.get(id=pk)
        serializer = RegisterSerializer(register, data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)
    except Register.DoesNotExist:
        return Response({'error': 'Register not found'}, status=404)

@api_view(['DELETE'])
def deleteRegister(request, pk):
    try:
        register = Register.objects.get(id=pk)
        register.delete()
        return Response({'message': 'Register was deleted'}, status=200)
    except Register.DoesNotExist:
        return Response({'error': 'Register not found'}, status=404)

# دوال DeliveryBoy
@api_view(['GET'])
def getDeliveryBoys(request):
    delivery_boys = DeliveryBoy.objects.all()
    serializer = DeliveryBoySerializer(delivery_boys, many=True, context={'request': request})
    return Response(serializer.data)

@api_view(['GET'])
def getDeliveryBoy(request, pk):
    try:
        delivery_boy = DeliveryBoy.objects.get(id=pk)
        serializer = DeliveryBoySerializer(delivery_boy, many=False, context={'request': request})
        return Response(serializer.data)
    except DeliveryBoy.DoesNotExist:
        return Response({'error': 'Delivery Boy not found'}, status=404)

@api_view(['POST'])
def createDeliveryBoy(request):
    serializer = DeliveryBoySerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        delivery_boy = serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=400)

@api_view(['PUT'])
def updateDeliveryBoy(request, pk):
    try:
        delivery_boy = DeliveryBoy.objects.get(id=pk)
        serializer = DeliveryBoySerializer(delivery_boy, data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)
    except DeliveryBoy.DoesNotExist:
        return Response({'error': 'Delivery Boy not found'}, status=404)

@api_view(['DELETE'])
def deleteDeliveryBoy(request, pk):
    try:
        delivery_boy = DeliveryBoy.objects.get(id=pk)
        delivery_boy.delete()
        return Response({'message': 'Delivery Boy was deleted'}, status=200)
    except DeliveryBoy.DoesNotExist:
        return Response({'error': 'Delivery Boy not found'}, status=404)

@api_view(['GET'])
def get_available_orders(request, email):
    try:
        logger.info(f"Getting available orders for delivery boy: {email}")
        delivery_boy_requesting = DeliveryBoy.objects.filter(email=email).first()
        if not delivery_boy_requesting:
            logger.error(f"Delivery Boy not found for email: {email}")
            return Response({'error': 'Delivery Boy not found'}, status=404)

        logger.info(f"Found delivery boy {delivery_boy_requesting.email} in governorate: {delivery_boy_requesting.governorate}")

        # Fetch assignments:
        # 1. Pending assignments in the delivery boy's governorate.
        # 2. Assignments already accepted by THIS delivery boy.
        assignments_query = DeliveryAssignment.objects.filter(
            Q(status='pending', recycle_bag__user__governorate=delivery_boy_requesting.governorate) |
            Q(status='accepted', delivery_boy=delivery_boy_requesting)
        ).select_related(
            'recycle_bag', 'recycle_bag__user', 'delivery_boy'
        ).prefetch_related(
            'recycle_bag__items', 'recycle_bag__items__item_type'
        ).order_by('-recycle_bag__created_at')

        logger.info(f"Found {assignments_query.count()} assignments for {email}")

        response_data = []
        for assignment in assignments_query:
            bag = assignment.recycle_bag
            user = bag.user
            
            items_data = []
            for item_in_bag in bag.items.all(): # Renamed item to item_in_bag to avoid conflict
                items_data.append({
                    'type': item_in_bag.item_type.name,
                    'quantity': item_in_bag.quantity,
                    'points': item_in_bag.points
                })

            order_data = {
                'assignment_id': assignment.id,
                'bag_id': bag.id,
                'status': assignment.status,
                'items': items_data,
                'governorate': user.governorate or '',
                'address': user.address or '',
                'created_at': bag.created_at.isoformat() if bag.created_at else None,
                'latitude': str(bag.latitude) if bag.latitude is not None else '',
                'longitude': str(bag.longitude) if bag.longitude is not None else '',
                'user_details': {
                    'name': f"{user.first_name} {user.last_name}".strip(),
                    'phone': user.phone_number,
                    'email': user.email
                },
                'delivery_boy': None
            }
            
            if assignment.status == 'accepted' and assignment.delivery_boy:
                # This will be the delivery_boy_requesting due to the query filter
                assigned_db = assignment.delivery_boy
                order_data['delivery_boy'] = {
                    'name': f"{assigned_db.first_name} {assigned_db.last_name}".strip(),
                    'phone': assigned_db.phone_number,
                    'rating': str(assigned_db.average_rating),
                    'email': assigned_db.email
                }
            
            response_data.append(order_data)
        
        logger.info(f"Successfully retrieved {len(response_data)} orders/assignments for {email}")
        return Response(response_data)

    except Exception as e:
        logger.error(f"Error in get_available_orders: {str(e)}")
        return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def accept_order(request, assignment_id):
    try:
        with transaction.atomic():
            logger.info(f"Attempting to accept assignment {assignment_id}")
            logger.info(f"Request data: {request.data}")
            
            assignment = DeliveryAssignment.objects.get(id=assignment_id)
            delivery_boy_email = request.data.get('email')
            
            if not delivery_boy_email:
                logger.error("No delivery boy email provided")
                return Response({'error': 'Delivery boy email is required'}, status=400)
            
            delivery_boy = DeliveryBoy.objects.get(email=delivery_boy_email)
            
            # Check if the delivery boy already has an active order
            if DeliveryAssignment.objects.filter(
                delivery_boy=delivery_boy,
                status__in=['in_transit']
            ).exists():
                logger.warning(f"Delivery boy {delivery_boy_email} already has an active order")
                return Response({
                    'error': 'You already have an active order'
                }, status=400)
            
            # Check if the assignment can be accepted
            if not assignment.can_be_accepted():
                logger.error(f"Assignment {assignment_id} cannot be accepted (current status: {assignment.status})")
                return Response({
                    'error': 'Order cannot be accepted'
                }, status=400)
            
            # Update assignment status to accepted
            assignment.status = 'accepted'
            assignment.delivery_boy = delivery_boy
            assignment.accepted_by = delivery_boy
            assignment.delivery_boy_phone = delivery_boy.phone_number
            assignment.user_phone = assignment.recycle_bag.user.phone_number
            assignment.save()
            
            # Update recycle bag status
            assignment.recycle_bag.status = 'accepted'
            assignment.recycle_bag.save()
            
            # Create notification for user
            Notification.objects.create(
                user=assignment.recycle_bag.user,
                message=f"Your order #{assignment.recycle_bag.id} has been accepted by {delivery_boy.first_name}"
            )
            
            logger.info(f"Successfully accepted assignment {assignment_id} by {delivery_boy_email}")
            return Response({
                'message': 'Order accepted successfully',
                'assignment_id': assignment.id,
                'status': assignment.status
            })
            
    except DeliveryAssignment.DoesNotExist:
        logger.error(f"Assignment {assignment_id} not found")
        return Response({'error': 'Assignment not found'}, status=404)
    except DeliveryBoy.DoesNotExist:
        logger.error(f"Delivery boy not found for email: {request.data.get('email')}")
        return Response({'error': 'Delivery boy not found'}, status=404)
    except Exception as e:
        logger.error(f"Error accepting assignment {assignment_id}: {str(e)}", exc_info=True) # Ensure this line belongs to the previous function
        return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def start_delivery_process(request, assignment_id):
    try:
        assignment = DeliveryAssignment.objects.select_related('recycle_bag', 'delivery_boy', 'recycle_bag__user').get(id=assignment_id)
        
        # Optional: Verify request is from the assigned delivery boy
        # delivery_boy_email = request.data.get('email')
        # if not delivery_boy_email or assignment.delivery_boy.email != delivery_boy_email:
        #     return Response({'error': 'Unauthorized or email not provided'}, status=403)

        if assignment.status != 'accepted':
            return Response({'error': f'Order cannot be started. Current status: {assignment.status}'}, status=400)

        with transaction.atomic():
            assignment.status = 'in_transit'
            assignment.save()

            recycle_bag = assignment.recycle_bag
            recycle_bag.status = 'in_transit'
            recycle_bag.save()

            # Notify user
            Notification.objects.create(
                user=recycle_bag.user,
                message=f"Your order #{recycle_bag.id} is now out for delivery with {assignment.delivery_boy.first_name}."
            )
            
            # Optionally, notify delivery boy (though they initiated it)
            # DeliveryBoyNotification.objects.create(
            #     delivery_boy=assignment.delivery_boy,
            #     message=f"You have started delivery for order #{recycle_bag.id}."
            # )

        logger.info(f"Delivery started for assignment {assignment_id} by delivery boy {assignment.delivery_boy.email}")
        return Response({
            'message': 'Delivery process started successfully.',
            'assignment_id': assignment.id,
            'status': assignment.status
        }, status=200)

    except DeliveryAssignment.DoesNotExist:
        return Response({'error': 'Assignment not found'}, status=404)
    except Exception as e:
        logger.error(f"Error starting delivery for assignment {assignment_id}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def cancel_order(request, assignment_id):
    """
    Allows an assigned delivery boy to cancel (unassign from) an accepted order,
    making it pending again.
    """
    try:
        delivery_boy_email = request.data.get('email')
        # cancel_reason = request.data.get('reason', 'No reason provided by delivery boy.') # Optional: if you want to store reason

        if not delivery_boy_email:
            return Response({'error': 'Delivery boy email is required.'}, status=400)

        with transaction.atomic():
            assignment = DeliveryAssignment.objects.select_related('recycle_bag', 'delivery_boy', 'recycle_bag__user').get(id=assignment_id)
            
            if not assignment.delivery_boy:
                logger.warning(f"Attempt to cancel unassigned order {assignment_id}")
                return Response({'error': 'Order is not currently assigned to any delivery boy.'}, status=400)

            if assignment.delivery_boy.email != delivery_boy_email:
                logger.warning(f"Unauthorized attempt to cancel order {assignment_id} by {delivery_boy_email}")
                return Response({'error': 'You are not authorized to cancel this order.'}, status=403)

            if assignment.status not in ['accepted']: # Or potentially ['accepted', 'in_transit'] if allowed
                logger.warning(f"Attempt to cancel order {assignment_id} with invalid status: {assignment.status}")
                return Response({'error': f'Order cannot be canceled. Current status: {assignment.status}'}, status=400)

            original_delivery_boy = assignment.delivery_boy # Keep a reference for notification
            recycle_bag = assignment.recycle_bag

            # Update Assignment to be pending and unassigned
            assignment.status = 'pending'
            assignment.delivery_boy = None
            assignment.accepted_by = None
            assignment.delivery_boy_phone = None # Clear previous boy's phone
            # assignment.cancel_reason = cancel_reason # If you add a field for this
            assignment.save()

            # Update RecycleBag status back to pending
            recycle_bag.status = 'pending'
            recycle_bag.save()

            # Notify User about the change
            Notification.objects.create(
                user=recycle_bag.user,
                message=f"Order #{recycle_bag.id} was unassigned by the delivery boy ({original_delivery_boy.first_name}). We are finding a new one."
            )

            # Notify the delivery boy who cancelled
            DeliveryBoyNotification.objects.create(
                delivery_boy=original_delivery_boy,
                message=f"You have successfully unassigned yourself from order #{recycle_bag.id}."
            )
            
            logger.info(f"Order {assignment_id} unassigned by {delivery_boy_email} and set to pending.")
            return Response({'message': 'Order successfully unassigned and returned to pending.'}, status=200)

    except DeliveryAssignment.DoesNotExist:
        logger.error(f"Cancel_order: Assignment {assignment_id} not found.")
        return Response({'error': 'Assignment not found.'}, status=404)
    # DeliveryBoy.DoesNotExist should ideally not be hit if assignment.delivery_boy was valid
    # but kept for robustness if data integrity issues could occur.
    except DeliveryBoy.DoesNotExist:
        logger.error(f"Cancel_order: DeliveryBoy associated with assignment {assignment_id} not found (should not happen).")
        return Response({'error': 'Associated delivery boy not found.'}, status=404)
    except Exception as e:
        logger.error(f"Error canceling/unassigning order {assignment_id}: {str(e)}", exc_info=True)
        return Response({'error': 'An error occurred while unassigning the order.'}, status=500)

@api_view(['POST'])
def reject_order(request, assignment_id):
    """
    Allows an assigned delivery boy to reject an order, providing a reason.
    The order becomes pending again for other delivery boys by creating a new assignment.
    """
    try:
        delivery_boy_email = request.data.get('email')
        reject_reason = request.data.get('reason')

        if not delivery_boy_email:
            return Response({'error': 'Delivery boy email is required.'}, status=400)
        if not reject_reason: # Make reason mandatory for rejection
            return Response({'error': 'Rejection reason is required.'}, status=400)

        with transaction.atomic():
            # Use select_related for efficiency
            current_assignment = DeliveryAssignment.objects.select_related(
                'recycle_bag', 'delivery_boy', 'recycle_bag__user'
            ).get(id=assignment_id)
            
            if not current_assignment.delivery_boy:
                logger.warning(f"Reject_order: Attempt to reject unassigned order {assignment_id}")
                return Response({'error': 'Order is not currently assigned to any delivery boy.'}, status=400)

            if current_assignment.delivery_boy.email != delivery_boy_email:
                logger.warning(f"Reject_order: Unauthorized attempt to reject order {assignment_id} by {delivery_boy_email}")
                return Response({'error': 'You are not authorized to reject this order.'}, status=403)

            # Allow rejection ONLY if 'in_transit'
            if current_assignment.status != 'in_transit':
                logger.warning(f"Reject_order: Attempt to reject order {assignment_id} with invalid status: {current_assignment.status}. Must be 'in_transit'.")
                return Response({'error': f'Order cannot be rejected. Current status must be "in_transit", but is: {current_assignment.status}'}, status=400)

            original_delivery_boy = current_assignment.delivery_boy
            recycle_bag = current_assignment.recycle_bag

            # Mark the current assignment as 'rejected'
            current_assignment.status = 'rejected'
            current_assignment.rejection_reason = reject_reason
            # The delivery_boy link remains on this 'rejected' assignment for historical purposes.
            current_assignment.save()
            
            # Update RecycleBag status to 'rejected'
            recycle_bag.status = 'rejected'
            recycle_bag.save()

            # Notify User
            Notification.objects.create(
                user=recycle_bag.user,
                message=f"Your order #{recycle_bag.id} has been rejected by the delivery boy. Reason: {reject_reason}. This order will not be processed further."
            )

            # Notify the delivery boy who rejected
            DeliveryBoyNotification.objects.create(
                delivery_boy=original_delivery_boy,
                message=f"You have rejected order #{recycle_bag.id}. Reason: {reject_reason}"
            )
            
            logger.info(f"Order assignment {assignment_id} (bag {recycle_bag.id}) rejected by {delivery_boy_email}. Reason: {reject_reason}. Order status set to rejected.")
            return Response({
                'message': 'Order rejected successfully. The order is now in a rejected state.',
                'rejected_assignment_id': current_assignment.id,
                'rejection_reason': reject_reason
            }, status=200)

    except DeliveryAssignment.DoesNotExist:
        logger.error(f"Reject_order: Assignment {assignment_id} not found.")
        return Response({'error': 'Assignment not found.'}, status=404)
    except DeliveryBoy.DoesNotExist: # Should be caught if email is provided but no such delivery boy
        logger.error(f"Reject_order: DeliveryBoy with email {request.data.get('email')} not found.")
        return Response({'error': 'Rejecting delivery boy not found.'}, status=404)
    except Exception as e:
        logger.error(f"Error rejecting order {assignment_id}: {str(e)}", exc_info=True)
        return Response({'error': 'An error occurred while rejecting the order.'}, status=500)

@api_view(['POST'])
def verify_order(request, assignment_id):
    try:
        with transaction.atomic():
            assignment = DeliveryAssignment.objects.get(id=assignment_id, status='accepted')
            items = request.data.get('items', [])
            discrepancy_report = request.data.get('discrepancy_report', '')

            if not items and not discrepancy_report:
                logger.error(f"No items or discrepancy report provided for assignment {assignment_id}")
                return Response({
                    'error': 'Must provide either items or discrepancy report'
                }, status=400)

            if discrepancy_report:
                assignment.discrepancy_report = discrepancy_report
                assignment.status = 'rejected'
                assignment.recycle_bag.status = 'pending'
                assignment.save()
                assignment.recycle_bag.save()

                # إعادة تعيين الطلب
                assign_order_to_delivery_boy(assignment.recycle_bag)

                Notification.objects.create(
                    user=assignment.recycle_bag.user,
                    message=f"Your order #{assignment.recycle_bag.id} was rejected due to discrepancies: {discrepancy_report}. It has been reassigned."
                )
                DeliveryBoyNotification.objects.create(
                    delivery_boy=assignment.delivery_boy,
                    message=f"Order #{assignment.recycle_bag.id} rejected due to discrepancies."
                )
                return Response({'message': 'Order rejected due to discrepancies'}, status=200)

            # التحقق من صحة العناصر
            if not items:
                logger.error(f"No items provided for assignment {assignment_id}")
                return Response({
                    'error': 'Must provide items for verification'
                }, status=400)

            # تحديث محتويات الـ RecycleBag
            logger.info(f"Updating items for bag {assignment.recycle_bag.id}")
            logger.info(f"Received items: {items}")
            
            # حذف العناصر القديمة
            assignment.recycle_bag.items.all().delete()
            
            points_per_unit = {
                'Plastic Bottle': 5,
                'Glass Bottle': 8,
                'Aluminum Can': 10
            }

            co2_per_unit = {
                'Plastic Bottle': 0.82,  # 0.82 كجم CO2 لكل زجاجة بلاستيك
                'Glass Bottle': 0.50,    # 0.50 كجم CO2 لكل زجاجة زجاج
                'Aluminum Can': 1.09     # 1.09 كجم CO2 لكل علبة ألومنيوم
            }
            
            total_points = 0
            total_co2 = 0
            new_items = []
            
            # التحقق من صحة كل عنصر قبل إضافته
            for item in items:
                item_type = ItemType.objects.filter(name=item['item_type']).first()
                if not item_type:
                    logger.error(f"Item type not found: {item['item_type']}")
                    continue
                
                quantity = int(item.get('quantity', 0))
                if quantity <= 0:
                    logger.error(f"Invalid quantity for item {item['item_type']}: {quantity}")
                    continue
                
                points = points_per_unit.get(item_type.name, 0) * quantity
                co2 = co2_per_unit.get(item_type.name, 0) * quantity
                
                total_points += points
                total_co2 += co2
                
                # تحديث قيمة CO2 للنوع إذا كانت 0
                if item_type.co2_per_unit == 0:
                    item_type.co2_per_unit = co2_per_unit.get(item_type.name, 0)
                    item_type.save()
                
                logger.info(f"Creating item: {item_type.name}, quantity: {quantity}, points: {points}, CO2: {co2}")
                
                new_items.append(
                    RecycleBagItem(
                        bag=assignment.recycle_bag,
                        item_type=item_type,
                        quantity=quantity,
                        points=points
                    )
                )

            # التحقق من وجود عناصر صحيحة على الأقل
            if not new_items:
                logger.error(f"No valid items found for assignment {assignment_id}")
                return Response({
                    'error': 'No valid items provided'
                }, status=400)

            # إضافة العناصر الجديدة
            RecycleBagItem.objects.bulk_create(new_items)

            assignment.status = 'in_transit'
            assignment.recycle_bag.status = 'in_transit'
            assignment.save()
            assignment.recycle_bag.save()

            logger.info(f"Total points for bag {assignment.recycle_bag.id}: {total_points}")
            logger.info(f"Total CO2 saved: {total_co2}")

            Notification.objects.create(
                user=assignment.recycle_bag.user,
                message=f"Your order #{assignment.recycle_bag.id} is now in transit with {assignment.delivery_boy.first_name} {assignment.delivery_boy.last_name}."
            )
            DeliveryBoyNotification.objects.create(
                delivery_boy=assignment.delivery_boy,
                message=f"Order #{assignment.recycle_bag.id} is now in transit."
            )
            return Response({
                'message': 'Order verified and in transit',
                'total_points': total_points,
                'items': [{
                    'item_type': item.item_type.name,
                    'quantity': item.quantity,
                    'points': item.points
                } for item in new_items]
            }, status=200)

    except DeliveryAssignment.DoesNotExist:
        logger.error(f"Assignment {assignment_id} not found or not accepted")
        return Response({'error': 'Assignment not found or not in accepted state'}, status=404)
    except Exception as e:
        logger.error(f"Error verifying order {assignment_id}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)
    
@api_view(['POST'])
def complete_order(request, assignment_id):
    try:
        with transaction.atomic():
            assignment = DeliveryAssignment.objects.get(id=assignment_id)
            
            if not assignment.can_be_delivered():
                return Response({
                    'error': 'Order cannot be marked as delivered'
                }, status=400)
            
            # تحديث حالة الطلب
            assignment.status = 'delivered'
            assignment.save()
            
            # تحديث حالة الحقيبة
            bag = assignment.recycle_bag
            bag.status = 'delivered'
            bag.save()
            
            # تحديث نقاط وإحصائيات المستخدم
            user = bag.user
            delivery_boy = assignment.delivery_boy
            
            total_points = 0
            total_co2 = Decimal('0.0')
            total_items = 0
            
            for item in bag.items.all():
                total_points += item.points
                total_co2 += item.item_type.co2_per_unit * item.quantity
                total_items += item.quantity
            
            user.points += total_points
            user.co2_saved += total_co2
            user.items_recycled += total_items
            user.rewards = (user.points // 20) # Assuming 20 user points = 1 EGP reward
            user.save()
            
            # تحديث إحصائيات عامل التوصيل
            points_for_delivery_boy = int(total_points * 0.10)  # 10% من نقاط المستخدم
            if delivery_boy: # Ensure delivery_boy is not None
                delivery_boy.points += points_for_delivery_boy
                delivery_boy.total_orders_delivered += 1
                # Calculate rewards for delivery boy (e.g., 10 EGP for every 100 points for delivery boy)
                delivery_boy.rewards = (delivery_boy.points // 100) * 10
                delivery_boy.save()

                # Activity for Delivery Boy - ASSUMPTION: DeliveryBoy model has a link to a Register profile
                # e.g., delivery_boy.register_user_profile or similar for activity logging.
                # If not, this part needs adjustment or a different activity model.
                try:
                    # Attempt to find a related Register profile for the DeliveryBoy to log activity
                    # This is a placeholder for actual logic to get/create a Register profile for the DeliveryBoy if needed for Activity.
                    # For simplicity, if DeliveryBoy itself is a Register or has a direct 'user' link:
                    # activity_user_for_db = delivery_boy.user
                    # If DeliveryBoy has a field like 'register_profile' linking to Register:
                    # activity_user_for_db = delivery_boy.register_profile
                    # If no such direct link, this Activity creation might need to be rethought or skipped for delivery_boy.
                    # For now, let's assume a hypothetical 'user_account' field on DeliveryBoy linking to Register.
                    if hasattr(delivery_boy, 'user_account') and delivery_boy.user_account:
                         Activity.objects.create(
                            user=delivery_boy.user_account, # Hypothetical link
                            title=f"Delivered order #{bag.id}",
                            points=points_for_delivery_boy,
                            type='delivered_order_db' # A new type for delivery boy activity
                        )
                    else:
                        logger.warning(f"Could not create activity for delivery boy {delivery_boy.email} due to missing user_account link.")
                except Exception as activity_err:
                    logger.error(f"Error creating activity for delivery boy {delivery_boy.email}: {activity_err}")

                # Notify Delivery Boy
                DeliveryBoyNotification.objects.create(
                    delivery_boy=delivery_boy,
                    message=f"Order #{bag.id} successfully delivered! You earned {points_for_delivery_boy} points."
                )

            # إنشاء نشاط للمستخدم (already exists, points variable name updated for clarity)
            Activity.objects.create(
                user=user,
                title=f"Order #{bag.id} delivered successfully",
                points=total_points, # Renamed from total_points to total_points_user for clarity if used above
                co2_saved=total_co2,
                type='delivered'
            )
            
            # إنشاء إشعار للمستخدم (already exists, points variable name updated)
            Notification.objects.create(
                user=user,
                message=f"Your order #{bag.id} has been delivered successfully! You earned {total_points} points!"
            )
            
            logger.info(f"Order {assignment_id} completed by {delivery_boy.email if delivery_boy else 'N/A'}")
            return Response({
                'message': 'Order completed successfully',
                'user_points_earned': total_points,
                'user_co2_saved': f"{total_co2:.2f}", # Format CO2 for consistency
                'user_items_recycled': total_items,
                'delivery_boy_points_earned': points_for_delivery_boy if delivery_boy else 0
            }, status=200)
            
    except DeliveryAssignment.DoesNotExist:
        return Response({'error': 'Assignment not found'}, status=404)
    except Exception as e:
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def get_delivery_history(request, email):
    try:
        delivery_boy = DeliveryBoy.objects.filter(email=email).first()
        if not delivery_boy:
            return Response({'error': 'Delivery Boy not found'}, status=404)

        assignments = DeliveryAssignment.objects.filter(delivery_boy=delivery_boy).order_by('-updated_at')
        serializer = DeliveryAssignmentSerializer(assignments, many=True, context={'request': request})
        return Response(serializer.data)
    except Exception as e:
        logger.error(f"Error fetching history for {email}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def get_delivery_dashboard(request, email):
    try:
        delivery_boy = DeliveryBoy.objects.filter(email=email).first()
        if not delivery_boy:
            return Response({'error': 'Delivery Boy not found'}, status=404)

        total_orders_delivered = delivery_boy.total_orders_delivered
        total_points = delivery_boy.points
        average_rating = delivery_boy.average_rating

        # Get active or recently used vouchers
        active_voucher = DeliveryBoyVoucher.objects.filter(
            delivery_boy=delivery_boy,
            is_used=False,
            expires_at__gt=timezone.now()
        ).first()

        # Calculate total voucher amount
        total_voucher_amount = DeliveryBoyVoucher.objects.filter(
            delivery_boy=delivery_boy,
            created_at__gte=timezone.now() - timezone.timedelta(days=30)  # Last 30 days
        ).aggregate(total=Sum('amount'))['total'] or 0

        # Use the direct rewards field from the model
        current_balance = delivery_boy.rewards

        # Get last 5 activities
        recent_assignments = DeliveryAssignment.objects.filter(
            delivery_boy=delivery_boy,
            status='delivered'
        ).order_by('-updated_at')[:5]

        recent_activities = [{
            'order_id': assignment.recycle_bag.id,
            'date': assignment.updated_at,
            'points_earned': 10,  # Each order = 10 points
            'status': 'Delivered'
        } for assignment in recent_assignments]

        return Response({
            'first_name': delivery_boy.first_name,
            'last_name': delivery_boy.last_name,
            'governorate': delivery_boy.governorate,
            'profile_image': request.build_absolute_uri(delivery_boy.image.url) if delivery_boy.image else None,
            'total_orders_delivered': total_orders_delivered,
            'total_points': total_points,
            'current_balance': max(current_balance, 0),  # Ensure balance doesn't go negative
            'average_rating': average_rating,
            'recent_activities': recent_activities,
            'points_to_next_reward': 20 - (total_points % 20),  # Points needed for next 1 EGP
            'next_reward_amount': 1.0,  # Next reward is 1 EGP
            'active_voucher': DeliveryBoyVoucherSerializer(active_voucher).data if active_voucher else None
        }, status=200)
    except Exception as e:
        logger.error(f"Error fetching dashboard for {email}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def get_delivery_notifications(request, email):
    try:
        delivery_boy = DeliveryBoy.objects.filter(email=email).first()
        if not delivery_boy:
            return Response({'error': 'Delivery Boy not found'}, status=404)

        notifications = DeliveryBoyNotification.objects.filter(delivery_boy=delivery_boy).order_by('-created_at')
        serializer = DeliveryBoyNotificationSerializer(notifications, many=True)
        return Response(serializer.data)
    except Exception as e:
        logger.error(f"Error fetching notifications for {email}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def mark_delivery_notification_as_read(request, notification_id):
    try:
        notification = DeliveryBoyNotification.objects.get(id=notification_id)
        notification.is_read = True
        notification.save()
        return Response({'message': 'Notification marked as read'}, status=200)
    except DeliveryBoyNotification.DoesNotExist:
        return Response({'error': 'Notification not found'}, status=404)
    except Exception as e:
        logger.error(f"Error marking notification {notification_id}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def assign_order_to_delivery_boy(request, order_id):
    try:
        logger.info(f"Attempting to assign order {order_id}")
        
        # Get the recycle bag
        recycle_bag = RecycleBag.objects.filter(id=order_id).first()
        if not recycle_bag:
            logger.error(f"Order {order_id} not found")
            return Response({'error': 'Order not found'}, status=404)

        # Check if order can be assigned
        if recycle_bag.status not in ['pending', 'assigned']:
            logger.error(f"Order {order_id} cannot be assigned (status: {recycle_bag.status})")
            return Response({'error': 'Order cannot be assigned'}, status=400)

        # Check for existing active assignment
        existing_assignment = DeliveryAssignment.objects.filter(
            recycle_bag=recycle_bag,
            status__in=['pending', 'accepted', 'in_transit']
        ).first()

        if existing_assignment:
            logger.info(f"Found existing active assignment for order {order_id}")
            return Response({
                'message': 'Order already assigned',
                'assignment': {
                    'id': existing_assignment.id,
                    'status': existing_assignment.status,
                    'delivery_boy': existing_assignment.delivery_boy.email if existing_assignment.delivery_boy else None
                }
            }, status=200)

        # Find available delivery boys in the same governorate
        available_delivery_boys = DeliveryBoy.objects.filter(
            governorate=recycle_bag.user.governorate,
            is_available=True
        )
        
        logger.info(f"Found {available_delivery_boys.count()} available delivery boys in {recycle_bag.user.governorate}")
        
        if not available_delivery_boys.exists():
            logger.warning(f"No available delivery boys found in {recycle_bag.user.governorate}")
            return Response({'error': 'No available delivery boys found in your area'}, status=404)

        # Select the delivery boy with the least number of active assignments
        delivery_boy = min(
            available_delivery_boys,
            key=lambda db: DeliveryAssignment.objects.filter(
                delivery_boy=db,
                status__in=['pending', 'accepted', 'in_transit']
            ).count()
        )

        # Create new assignment
        assignment = DeliveryAssignment.objects.create(
            recycle_bag=recycle_bag,
            delivery_boy=delivery_boy,
            status='pending'
        )

        # Update recycle bag status
        recycle_bag.status = 'assigned'
        recycle_bag.save()

        # Create notification for delivery boy
        DeliveryBoyNotification.objects.create(
            delivery_boy=delivery_boy,
            message=f'New order #{order_id} has been assigned to you'
        )

        logger.info(f"Successfully assigned order {order_id} to {delivery_boy.email}")
        return Response({
            'message': 'Order assigned successfully',
            'assignment': {
                'id': assignment.id,
                'delivery_boy': {
                    'email': delivery_boy.email,
                    'name': f"{delivery_boy.first_name} {delivery_boy.last_name}",
                    'governorate': delivery_boy.governorate
                }
            }
        })

    except Exception as e:
        logger.error(f"Error assigning order {order_id}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)
    
@api_view(['POST'])
def place_order(request):
    logger.info(f"Received place_order request: {request.data}")
    data = request.data
    email = data.get('email') or data.get('user_email')
    latitude = data.get('latitude')
    longitude = data.get('longitude')
    items = data.get('items', [])

    if not email:
        logger.error("Email or user_email is required but not provided")
        return Response({'error': 'Email is required'}, status=400)

    if not items:
        logger.error("Items are required but not provided")
        return Response({'error': 'Items are required'}, status=400)

    try:
        user = Register.objects.get(email=email)
    except Register.DoesNotExist:
        logger.error(f"User not found for email: {email}")
        return Response({'error': 'User not found'}, status=404)

    if RecycleBag.objects.filter(user=user, status='pending').exists():
        logger.warning(f"Pending bag already exists for {email}")
        return Response({'error': 'A pending order already exists'}, status=400)

    try:
        with transaction.atomic():
            # تحويل الإحداثيات إلى Decimal إذا كانت موجودة
            try:
                latitude = Decimal(str(latitude)) if latitude is not None else None
                longitude = Decimal(str(longitude)) if longitude is not None else None
            except (TypeError, ValueError, InvalidOperation):
                latitude = None
                longitude = None
                logger.warning(f"Invalid coordinates provided: lat={latitude}, long={longitude}")

            bag = RecycleBag.objects.create(
                user=user,
                status='pending',
                latitude=latitude,
                longitude=longitude
            )

            logger.info(f"Created new bag with ID {bag.id} and coordinates: lat={latitude}, long={longitude}")

            points_per_unit = {
                'Plastic Bottle': 5,
                'Glass Bottle': 8,
                'Aluminum Can': 10
            }

            total_points = 0
            for item in items:
                item_type_obj, _ = ItemType.objects.get_or_create(name=item['item_type'])
                if item_type_obj.name not in points_per_unit:
                    logger.error(f"Invalid item type: {item_type_obj.name}")
                    continue
                points = points_per_unit[item_type_obj.name] * item['quantity']
                if points < 0:
                    logger.error(f"Negative points calculated for item {item_type_obj.name}")
                    continue
                total_points += points
                RecycleBagItem.objects.create(
                    bag=bag,
                    item_type=item_type_obj,
                    quantity=item['quantity'],
                    points=points
                )

            # Create a pending DeliveryAssignment without assigning a specific delivery boy yet
            # The delivery_boy will be set when one accepts the order via the accept_order endpoint
            DeliveryAssignment.objects.create(
                recycle_bag=bag,
                status='pending'
            )
            logger.info(f"Created pending assignment for bag ID {bag.id}. It will be visible to all relevant delivery boys.")
            # Note: Notifications to specific delivery boys about a new order
            # should ideally be handled by a separate mechanism or when they poll for available orders,
            # rather than picking one here. For now, they will see it when they call get_available_orders.

            # إنشاء إشعار للعميل
            Notification.objects.create(
                user=user,
                message=f"Your order #{bag.id} has been placed successfully and is pending assignment."
            )

            # إنشاء نشاط لتسجيل الطلب
            Activity.objects.create(
                user=user,
                title=f"Order {bag.id} Placed",
                points=0,
                type="placed",
                date=timezone.now()
            )

            order_details = {
                'order_id': bag.id,
                'customer_name': f"{user.first_name} {user.last_name}",
                'customer_phone': user.phone_number,
                'location': {
                    'latitude': str(latitude) if latitude is not None else '',
                    'longitude': str(longitude) if longitude is not None else ''
                },
                'items': [
                    {
                        'item_type': item.item_type.name,
                        'quantity': item.quantity,
                        'points': item.points
                    } for item in bag.items.all()
                ],
                'total_points': total_points,
                'rewards': int(total_points / 20),
                'status': bag.status,
                'created_at': bag.created_at,
                'delivery_boy': None # Initially no delivery boy is assigned
            }
            logger.info(f"Placed order for {email} with bag ID {bag.id}")
            return Response({
                'message': 'Order placed successfully',
                'order': order_details
            }, status=201)

    except Exception as e:
        logger.error(f"Error in place_order for {email}: {str(e)}")
        return Response({'error': str(e)}, status=500)
    
@api_view(['PUT'])
def updatePassword(request):
    try:
        email = request.data.get('email')
        new_password = request.data.get('password')
        user_type = request.data.get('user_type')

        if not email or not new_password or not user_type:
            return Response({'error': 'Email, password, and user_type are required'}, status=400)

        if user_type == 'regular_user':
            user = Register.objects.filter(email=email).first()
        elif user_type == 'delivery_boy':
            user = DeliveryBoy.objects.filter(email=email).first()
        else:
            return Response({'error': 'Invalid user_type'}, status=400)

        if not user:
            return Response({'error': 'User not found'}, status=404)

        user.password = make_password(new_password)
        user.save()

        return Response({'message': 'Password updated successfully'}, status=200)
    except Exception as e:
        logger.error(f"Error updating password for {email}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def get_user_profile(request):
    try:
        email = request.GET.get('email')
        user_type = request.GET.get('user_type')

        if not email or not user_type:
            return Response({'error': 'Email and user_type are required'}, status=400)

        if user_type == 'regular_user':
            user = Register.objects.filter(email=email).first()
            if not user:
                return Response({'error': 'User not found'}, status=404)
            data = {
                'first_name': user.first_name,
                'last_name': user.last_name,
                'gender': user.gender,
                'dob': user.birth_date.strftime("%d-%m-%Y") if user.birth_date else '',
                'governorate': user.governorate,
                'type': user.type,
                'email': user.email,
                'phone': user.phone_number,
                'profile_image': request.build_absolute_uri(user.image.url) if user.image else None,
                'user_type': 'regular_user',
            }
        elif user_type == 'delivery_boy':
            user = DeliveryBoy.objects.filter(email=email).first()
            if not user:
                return Response({'error': 'Delivery Boy not found'}, status=404)
            data = {
                'first_name': user.first_name,
                'last_name': user.last_name,
                'gender': user.gender,
                'dob': user.birth_date.strftime("%d-%m-%Y") if user.birth_date else '',
                'governorate': user.governorate,
                'type': user.type,
                'email': user.email,
                'phone': user.phone_number,
                'profile_image': request.build_absolute_uri(user.image.url) if user.image else None,
                'total_orders_delivered': user.total_orders_delivered,  # تغيير total_orders_completed إلى total_orders_delivered
                'average_rating': user.average_rating,
                'user_type': 'delivery_boy',
            }
        else:
            return Response({'error': 'Invalid user_type'}, status=400)

        return Response(data, status=200)
    except Exception as e:
        logger.error(f"Error fetching profile for {email}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)
    
@api_view(['POST'])
def updateProfile(request):
    try:
        email = request.data.get('email')
        user_type = request.data.get('user_type')

        if not email or not user_type:
            return Response({'error': 'Email and user_type are required'}, status=400)

        if user_type == 'regular_user':
            user = Register.objects.filter(email=email).first()
        elif user_type == 'delivery_boy':
            user = DeliveryBoy.objects.filter(email=email).first()
        else:
            return Response({'error': 'Invalid user_type'}, status=400)

        if not user:
            return Response({'error': 'User not found'}, status=404)

        user.first_name = request.data.get('first_name', user.first_name)
        user.last_name = request.data.get('last_name', user.last_name)
        user.gender = request.data.get('gender', user.gender)
        user.governorate = request.data.get('governorate', user.governorate)
        user.type = request.data.get('type', user.type)  # إضافة دعم لتحديث حقل type
        user.phone_number = request.data.get('phone', user.phone_number)

        dob = request.data.get('dob')
        if dob:
            try:
                user.birth_date = datetime.strptime(dob, "%d-%m-%Y").date()
            except ValueError:
                return Response({'error': 'Invalid date format. Use DD-MM-YYYY.'}, status=400)

        if 'profile_image' in request.FILES:
            user.image = request.FILES['profile_image']

        user.save()
        return Response({'message': 'Profile updated successfully'}, status=200)
    except Exception as e:
        logger.error(f"Error updating profile for {email}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['PUT', 'POST'])
def updatePointsAndRewards(request):
    try:
        email = request.data.get('email')
        points = request.data.get('points')
        rewards = request.data.get('rewards')

        # التأكد إن البيانات المطلوبة موجودة
        if not email or points is None or rewards is None:
            logger.error(f"Missing email, points, or rewards in request: {request.data}")
            return Response({'error': 'Email, points, and rewards are required'}, status=400)

        user = Register.objects.filter(email=email).first()
        if not user:
            logger.error(f"User not found for email: {email}")
            return Response({'error': 'User not found'}, status=404)

        # تحويل points وrewards لأرقام
        try:
            points = int(points)
            rewards = int(rewards)
        except (ValueError, TypeError):
            logger.error(f"Invalid points or rewards format: points={points}, rewards={rewards}")
            return Response({'error': 'Invalid points or rewards format'}, status=400)

        # تحديث الـ points وrewards مباشرة من القيم المرسلة
        user.points = max(points, 0)
        user.rewards = rewards
        user.save()

        # التحقق من الأنشطة (للتأكد إن القيم منطقية)
        activities = Activity.objects.filter(user=user)
        total_points_from_activities = sum(activity.points for activity in activities)
        logger.info(f"Points from activities for {email}: {total_points_from_activities}, Points set: {user.points}")

        # لو فيه تعارض كبير، بنسجل الخطأ
        if abs(total_points_from_activities - user.points) > 1:  # نعطي هامش صغير للتقريب
            logger.warning(f"Points mismatch for {email}: activities={total_points_from_activities}, set={user.points}")

        logger.info(f"Updated points for {email}: points={user.points}, rewards={user.rewards}")
        return Response({
            'message': 'Points and rewards updated successfully',
            'points': user.points,
            'rewards': user.rewards
        }, status=200)
    except Exception as e:
        logger.error(f"Error updating points for {email}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def get_user_balance(request, email):
    try:
        user = Register.objects.filter(email=email).first()
        if not user:
            logger.error(f"User not found for email: {email}")
            return Response({'error': 'User not found'}, status=404)

        points = user.points
        rewards = int(points / 20)

        last_activity = Activity.objects.filter(user=user).order_by('-date').first()

        last_activity_details = None
        if last_activity:
            title = last_activity.title
            if last_activity.type == 'redeem':
                voucher_amount = abs(last_activity.points) / 20
                title = f"Redeemed voucher worth {voucher_amount} EGP"
            elif last_activity.type == 'earn':
                title = "GoRecycle"
            elif last_activity.type == 'cancel':
                title = "Order Cancelled"
            elif last_activity.type == 'delivered':
                title = f"Order {last_activity.title.split()[-2]} Delivered"
            elif last_activity.type == 'rejected':
                title = f"Order {last_activity.title.split()[-2]} Rejected"
            elif last_activity.type == 'accepted':
                title = f"Order {last_activity.title.split()[-4]} Accepted by Delivery Boy"

            # التعامل مع جميع الحالات
            if last_activity.points > 0:
                last_activity_details = {
                    'type': 'recycle',
                    'points': last_activity.points,
                    'title': title,
                    'date': last_activity.date.isoformat()
                }
            elif last_activity.points < 0:
                last_activity_details = {
                    'type': 'voucher_redeem',
                    'voucher_amount': abs(last_activity.points) / 20,
                    'title': title,
                    'date': last_activity.date.isoformat()
                }
            else:  # points == 0
                last_activity_details = {
                    'type': last_activity.type,
                    'points': 0,
                    'title': title,
                    'date': last_activity.date.isoformat()
                }

        logger.info(f"Fetched balance for {email}: points={points}, rewards={rewards}, last_activity={last_activity_details}")
        return Response({
            'points': points,
            'rewards': rewards,
            'last_activity': last_activity_details
        }, status=200)
    except Exception as e:
        logger.error(f"Error fetching balance for {email}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)
    
@api_view(['POST'])
def generate_qr_code_for_user(request):
    """
    Generate QR code for a user with a specific amount, similar to delivery boy voucher generation.
    """
    try:
        email = request.data.get('email')
        amount_str = request.data.get('amount')

        if not email:
            return Response({'error': 'Email is required'}, status=400)
        if not amount_str:
            return Response({'error': 'Amount is required'}, status=400)

        logger.info(f"Generating voucher for user: {email}")
        logger.info(f"Request data: {request.data}")

        with transaction.atomic():
            user = Register.objects.select_for_update().get(email=email)
            if not user: # Should be caught by get_object_or_404 if not found, but good practice
                logger.error(f"User not found: {email}")
                return Response({'error': 'User not found'}, status=404)
            
            logger.info(f"Found user with rewards: {user.rewards}")

            # Check for active voucher
            active_voucher = CustomerVoucher.objects.filter(
                user=user,
                is_used=False,
                expires_at__gt=timezone.now()
            ).first()
            
            if active_voucher:
                logger.info(f"Active voucher found for {email}")
                # Pass request to serializer context if available
                serializer_context = {'request': request} if hasattr(request, 'build_absolute_uri') else {}
                return Response({
                    'error': 'You already have an active voucher',
                    'active_voucher': CustomerVoucherSerializer(active_voucher, context=serializer_context).data
                }, status=400)

            try:
                amount = Decimal(amount_str)
            except InvalidOperation:
                return Response({'error': 'Invalid amount format'}, status=400)

            if amount <= 0:
                return Response({'error': 'Amount must be greater than 0'}, status=400)
            
            # For customers, 'rewards' is their EGP balance.
            # The minimum voucher amount is 10 EGP (handled by frontend, but good to check here too)
            if amount < 10:
                return Response({'error': 'Minimum voucher amount is 10 EGP'}, status=400)

            if user.rewards < amount:
                return Response({
                    'error': f'Insufficient rewards. You need {amount} EGP for this voucher. Current rewards: {user.rewards} EGP'
                }, status=400)

            # Generate unique voucher code (8 characters like delivery boy)
            code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
            while CustomerVoucher.objects.filter(code=code).exists():
                code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))

            # Create voucher
            voucher = CustomerVoucher.objects.create(
                user=user,
                code=code,
                amount=amount,
                expires_at=timezone.now() + timezone.timedelta(hours=48) # 48 hours expiry
            )

            logger.info(f"Before deduction - User ID: {user.id}, Rewards: {user.rewards}")
            logger.info(f"Voucher amount: {amount}")

            # Deduct rewards using F() expressions for atomic update
            # Customer rewards are stored as integer, amount is Decimal
            amount_to_deduct_rewards = int(amount)

            updated_count = Register.objects.filter(pk=user.id).update(
                rewards=F('rewards') - amount_to_deduct_rewards
            )

            if updated_count == 0:
                logger.error(f"User record with pk={user.id} was NOT updated by F() expression. This is unexpected.")
                # This might indicate a concurrency issue or that the balance was already too low.
                # The initial check user.rewards < amount should prevent this, but good to log.
                raise Exception("Failed to deduct rewards, possibly due to a concurrent update or insufficient balance.")
            else:
                logger.info(f"User record with pk={user.id} was targeted by F() expression (updated_count: {updated_count}).")
            
            user.refresh_from_db()
            logger.info(f"After F() update and refresh_from_db - DB Rewards: {user.rewards}")
            
            # Create notification
            Notification.objects.create(
                user=user,
                message=f"Voucher generated successfully for {amount} EGP. Code: {code}. Expires in 48 hours."
            )

            # Create activity (type 'redeem' as it's redeeming rewards for a voucher)
            # Assuming 20 points = 1 EGP for activity logging consistency with ActivitySerializer
            points_for_activity = -int(amount * 20)
            Activity.objects.create(
                user=user,
                title=f"Redeemed {amount} EGP for voucher",
                points=points_for_activity,
                type='redeem' # This signifies spending/using rewards
            )
            
            logger.info(f"Successfully generated voucher for {email}: {code}. Activity points: {points_for_activity}")
            # Pass request to serializer context
            serializer_context = {'request': request} if hasattr(request, 'build_absolute_uri') else {}
            return Response({
                'message': 'Voucher generated successfully',
                'voucher': CustomerVoucherSerializer(voucher, context=serializer_context).data,
                'remaining_rewards': user.rewards
            })

    except Register.DoesNotExist:
        return Response({'error': 'User not found'}, status=404)
    except Exception as e:
        logger.error(f"Error generating user voucher: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def use_qr_code(request):
    """
    Use a QR code at a specific branch
    """
    try:
        code = request.data.get('code')
        branch_id = request.data.get('branch_id')

        if not code or not branch_id:
            return Response({'error': 'Code and branch_id are required'}, status=400)

        voucher = get_object_or_404(CustomerVoucher, code=code, is_used=False)
        branch = get_object_or_404(Branch, id=branch_id)

        # Check if voucher has expired
        if voucher.expires_at < timezone.now():
            voucher.is_used = True
            voucher.save()
            return Response({'error': 'Voucher has expired'}, status=400)

        # Create QR code usage record
        usage = QRCodeUsage.objects.create(
            user=voucher.user,
            branch=branch,
            amount=voucher.amount
        )

        # Update voucher
        voucher.is_used = True
        voucher.used_branch = branch
        voucher.save()

        # Create notification
        message = f"Your voucher worth {voucher.amount} EGP was used at {branch.name}"
        Notification.objects.create(user=voucher.user, message=message)

        return Response({
            'message': 'QR code used successfully',
            'usage': QRCodeUsageSerializer(usage).data
        })

    except Exception as e:
        logger.error(f"Error using QR code: {str(e)}")
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def check_voucher_status(request, email):
    """
    Check if a user has an active voucher
    """
    try:
        user = get_object_or_404(Register, email=email)
        active_voucher = CustomerVoucher.objects.filter(
            user=user,
            is_used=False,
            expires_at__gt=timezone.now()
        ).first()

        if active_voucher:
            # Pass request to serializer context
            serializer_context = {'request': request} if hasattr(request, 'build_absolute_uri') else {}
            return Response({
                'has_active_voucher': True,
                'active_voucher': CustomerVoucherSerializer(active_voucher, context=serializer_context).data # Changed 'voucher' to 'active_voucher' for consistency
            })
        else:
            return Response({
                'has_active_voucher': False,
                'message': 'No active voucher found' # Added message for consistency
            })

    except Register.DoesNotExist: # Specific exception
        return Response({'error': 'User not found'}, status=404)
    except Exception as e:
        logger.error(f"Error checking user voucher status: {str(e)}", exc_info=True) # Added exc_info and specific log message
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def qr_usage_history(request, email):
    """
    Get QR code usage history for a user
    """
    try:
        user = get_object_or_404(Register, email=email)
        usages = QRCodeUsage.objects.filter(user=user).order_by('-used_at')
        return Response(QRCodeUsageSerializer(usages, many=True).data)

    except Exception as e:
        logger.error(f"Error getting QR usage history: {str(e)}")
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def get_pending_bags(request, email):
    try:
        user = Register.objects.filter(email=email).first()
        if not user:
            logger.error(f"User not found for email: {email}")
            return Response({'error': 'User not found'}, status=404)

        bags = RecycleBag.objects.filter(user=user, status__in=['pending', 'assigned']).order_by('-created_at').distinct()
        serializer = RecycleBagSerializer(bags, many=True, context={'request': request})
        logger.info(f"Retrieved {len(bags)} pending bags for {email}")
        return Response(serializer.data)
    except Exception as e:
        logger.error(f"Error in get_pending_bags for {email}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def cancel_bag(request, bag_id):
    logger.info(f"Cancelling bag {bag_id} at {timezone.now()}")
    try:
        with transaction.atomic():
            bag = RecycleBag.objects.filter(id=bag_id, status__in=['pending', 'assigned']).first()
            if not bag:
                logger.error(f"Bag {bag_id} not found or not pending/assigned")
                return Response({'error': 'Recycling bag not found or not pending/assigned'}, status=404)

            if Activity.objects.filter(user=bag.user, title=f"Canceled recycling bag {bag_id}").exists():
                logger.warning(f"Duplicate cancellation attempt for bag {bag_id}")
                return Response({'error': 'Bag already canceled'}, status=400)

            bag.status = 'canceled'
            bag.save()

            Activity.objects.create(
                user=bag.user,
                title=f"Canceled recycling bag {bag_id}",
                points=0,
                co2_saved=0.0,
                type='canceled',
                date=timezone.now()
            )
            logger.info(f"Created cancel activity for bag {bag_id} with 0 points")

            message = f"Your recycling request (Bag ID: {bag.id}) was canceled on {timezone.now().strftime('%Y-%m-%d %I:%M %p')}"
            Notification.objects.create(user=bag.user, message=message)

            assignment = DeliveryAssignment.objects.filter(recycle_bag=bag, status__in=['pending', 'accepted']).first()
            if assignment:
                DeliveryBoyNotification.objects.create(
                    delivery_boy=assignment.delivery_boy,
                    message=f"Order {bag.id} was canceled by the user"
                )

            return Response({'message': f'Recycling bag {bag_id} canceled successfully'}, status=200)
    except Exception as e:
        logger.error(f"Error cancelling bag {bag_id}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def get_all_bags(request, email):
    try:
        user = Register.objects.get(email=email)
        bags = RecycleBag.objects.filter(user=user)  # Removed the exclude filter
        bags_data = []
        for bag in bags:
            items = []
            for item in bag.items.all():
                items.append({
                    'item_type': item.item_type.name,
                    'quantity': item.quantity,
                    'points': item.points,
                })
            bags_data.append({
                'id': bag.id,
                'items': items,
                'date': bag.created_at.strftime("%Y-%m-%d %H:%M:%S"),
                'status': bag.status,
            })
        logger.info(f"Retrieved {len(bags)} bags for {email}")
        return Response(bags_data, status=200)
    except Register.DoesNotExist:
        return Response({'error': 'User not found'}, status=404)
    except Exception as e:
        logger.error(f"Error in get_all_bags for {email}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def confirm_order(request):
    logger.info(f"Confirming order at {timezone.now()}")
    bag_id = request.data.get('bag_id')
    try:
        with transaction.atomic():
            bag = RecycleBag.objects.get(id=bag_id, status='delivered')
            if Activity.objects.filter(user=bag.user, title=f"Confirmed recycling order {bag.id}").exists():
                logger.warning(f"Duplicate confirmation attempt for order {bag_id}")
                return Response({'error': 'Order already confirmed'}, status=400)

            total_points = sum([item.points for item in bag.items.all()])
            bag.status = 'completed'
            bag.save()

            Activity.objects.create(
                user=bag.user,
                title=f"Confirmed recycling order {bag.id}",
                points=total_points,
                type="earn",
                date=timezone.now()
            )
            logger.info(f"Created earn activity for order {bag_id} with {total_points} points")

            message = f"Your recycling order has been confirmed! You earned {total_points} points on {bag.created_at.strftime('%Y-%m-%d %I:%M %p')}"
            Notification.objects.create(user=bag.user, message=message)

            user = bag.user
            activities = Activity.objects.filter(user=user)
            user.points = max(sum(activity.points for activity in activities), 0)
            user.rewards = int(user.points / 20)
            user.save()
            logger.info(f"Updated user {user.email}: points={user.points}, rewards={user.rewards}")

            return Response({
                'message': 'Order confirmed successfully',
                'points_added': total_points
            }, status=200)
    except RecycleBag.DoesNotExist:
        logger.error(f"Order {bag_id} not found")
        return Response({'error': 'Order not found'}, status=404)
    except Exception as e:
        logger.error(f"Error in confirm_order for bag_id {bag_id}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def user_orders(request, email):
    try:
        user = Register.objects.get(email=email)
        bags = RecycleBag.objects.filter(user=user).order_by('-created_at')
        serializer = RecycleBagSerializer(bags, many=True, context={'request': request})
        logger.info(f"Retrieved {len(bags)} orders for {email}")
        return Response(serializer.data)
    except Register.DoesNotExist:
        return Response({'error': 'User not found'}, status=404)
    except Exception as e:
        logger.error(f"Error in user_orders for {email}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def get_stores(request):
    try:
        stores = Store.objects.all()
        serializer = StoreSerializer(stores, many=True, context={'request': request})
        logger.info(f"Retrieved {len(stores)} stores")
        return Response(serializer.data)
    except Exception as e:
        logger.error(f"Error fetching stores: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def get_notifications(request, email):
    logger.info(f"Fetching notifications for email: {email}")
    try:
        user = Register.objects.filter(email=email).first()
        if not user:
            logger.error(f"User not found for email: {email}")
            return Response({'error': 'User not found'}, status=404)

        notifications = Notification.objects.filter(user=user).order_by('-created_at')
        serializer = NotificationSerializer(notifications, many=True)
        logger.info(f"Retrieved {len(notifications)} notifications for {email}")
        return Response(serializer.data)
    except Exception as e:
        logger.error(f"Error fetching notifications for {email}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def mark_notification_as_read(request, notification_id):
    logger.info(f"Attempting to mark notification {notification_id} as read")
    try:
        notification = Notification.objects.get(id=notification_id)
        notification.is_read = True
        notification.save()
        logger.info(f"Notification {notification_id} marked as read")
        return Response({'message': 'Notification marked as read'})
    except Notification.DoesNotExist:
        logger.error(f"Notification {notification_id} not found")
        return Response({'error': 'Notification not found'}, status=404)
    except Exception as e:
        logger.error(f"Error marking notification {notification_id}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['DELETE'])
def clear_notifications(request, email):
    logger.info(f"Clearing notifications for email: {email}")
    try:
        user = Register.objects.filter(email=email).first()
        if not user:
            logger.error(f"User not found for email: {email}")
            return Response({'error': 'User not found'}, status=404)

        Notification.objects.filter(user=user).delete()
        logger.info(f"All notifications cleared for {email}")
        return Response({'message': 'All notifications cleared'})
    except Exception as e:
        logger.error(f"Error clearing notifications for {email}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def get_activities(request, email):
    logger.info(f"Fetching activities for email: {email}")
    try:
        user = Register.objects.filter(email=email).first()
        if not user:
            logger.error(f"User not found for email: {email}")
            return Response({'error': 'User not found'}, status=404)

        activities = Activity.objects.filter(user=user).order_by('-date')
        serializer = ActivitySerializer(activities, many=True)
        logger.info(f"Retrieved {len(activities)} activities for {email}")
        return Response(serializer.data)
    except Exception as e:
        logger.error(f"Error fetching activities for {email}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def add_activities(request, email):
    logger.info(f"Adding activities for email: {email}")
    try:
        user = Register.objects.filter(email=email).first()
        if not user:
            logger.error(f"User not found for email: {email}")
            return Response({'error': 'User not found'}, status=404)

        activities_data = request.data.get('activities', [])
        for activity in activities_data:
            points = activity['points']
            if points < 0 and activity['type'] == 'earn':
                logger.error(f"Invalid points {points} for earn activity")
                continue
            if points > 0 and activity['type'] == 'redeem':
                logger.error(f"Invalid points {points} for redeem activity")
                continue
            Activity.objects.create(
                user=user,
                title=activity['title'],
                points=points,
                type=activity['type'],
                date=activity['date']
            )
        logger.info(f"Added {len(activities_data)} activities for {email}")

        user.points = max(sum(activity.points for activity in Activity.objects.filter(user=user)), 0)
        user.rewards = int(user.points / 20)
        user.save()
        logger.info(f"Updated user {email}: points={user.points}, rewards={user.rewards}")

        return Response({'message': 'Activities added successfully'}, status=201)
    except Exception as e:
        logger.error(f"Error adding activities for {email}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def get_total_recycled_items(request, email):
    try:
        user = Register.objects.filter(email=email).first()
        if not user:
            logger.error(f"User not found for email: {email}")
            return Response({'error': 'User not found'}, status=404)
 
        total_items = RecycleBagItem.objects.filter(
            bag__user=user,
            bag__status__in=['completed', 'delivered']  # تحديث هنا لتشمل الحالتين
        ).aggregate(total=Sum('quantity'))['total'] or 0

        co2_saved = sum(
            item.quantity * item.item_type.co2_per_unit 
            for item in RecycleBagItem.objects.filter(
                bag__user=user, 
                bag__status__in=['completed', 'delivered']  # تحديث هنا أيضاً
            )
        )

        logger.info(f"Retrieved total recycled items for {email}: {total_items}")
        logger.info(f"Retrieved total CO2 saved for {email}: {co2_saved}")

        return JsonResponse({
            'total_items': total_items,
            'co2_saved': co2_saved
        })
    except Exception as e:
        logger.error(f"Error fetching total recycled items for {email}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def generate_delivery_boy_voucher(request, email):
    """Generate a voucher for a delivery boy"""
    try:
        if not email:
            return Response({'error': 'Email is required'}, status=400)

        logger.info(f"Generating voucher for delivery boy: {email}")
        logger.info(f"Request data: {request.data}")
        
        with transaction.atomic():
            delivery_boy = DeliveryBoy.objects.select_for_update().get(email=email)
            if not delivery_boy:
                logger.error(f"Delivery Boy not found: {email}")
                return Response({'error': 'Delivery Boy not found'}, status=404)
                
            logger.info(f"Found delivery boy with points: {delivery_boy.points}")
            
            # Check for active voucher
            active_voucher = DeliveryBoyVoucher.objects.filter(
                delivery_boy=delivery_boy,
                is_used=False,
                expires_at__gt=timezone.now()
            ).first()
            
            if active_voucher:
                logger.info(f"Active voucher found for {email}")
                return Response({
                    'error': 'You already have an active voucher',
                    'active_voucher': DeliveryBoyVoucherSerializer(active_voucher).data
                }, status=400)

            # Get amount from request
            try:
                amount = float(request.data.get('amount', 0))
            except (TypeError, ValueError):
                return Response({'error': 'Invalid amount'}, status=400)

            if amount <= 0:
                return Response({'error': 'Amount must be greater than 0'}, status=400)

            # Calculate required points (20 points = 1 EGP)
            required_points = int(amount * 20)
            
            # Check if delivery boy has enough rewards
            if delivery_boy.rewards < amount:
                return Response({
                    'error': f'Insufficient rewards. You need {amount} EGP in rewards for this voucher. Current rewards: {delivery_boy.rewards} EGP'
                }, status=400)

            # Check if delivery boy has enough points
            if delivery_boy.points < required_points:
                return Response({
                    'error': f'Insufficient points. You need {required_points} points for {amount} EGP voucher. Current points: {delivery_boy.points}'
                }, status=400)

            # Generate unique voucher code
            code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
            while DeliveryBoyVoucher.objects.filter(code=code).exists():
                code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))

            # Create voucher
            voucher = DeliveryBoyVoucher.objects.create(
                delivery_boy=delivery_boy,
                code=code,
                amount=amount,
                expires_at=timezone.now() + timezone.timedelta(hours=48)
            )

            logger.info(f"Before deduction - Delivery Boy ID: {delivery_boy.id}, Points: {delivery_boy.points}, Rewards: {delivery_boy.rewards}")
            logger.info(f"Voucher amount: {amount}, Required points for deduction: {required_points}")

            # Deduct rewards and points using F() expressions for atomic update
            amount_to_deduct_rewards_as_int = int(amount) # 'amount' is float from request.data

            logger.info(f"Attempting F() expression update for DeliveryBoy ID: {delivery_boy.id}. Current Points: {delivery_boy.points}, Current Rewards: {delivery_boy.rewards}")
            logger.info(f"Deducting Points: {required_points}, Deducting Rewards: {amount_to_deduct_rewards_as_int}")

            updated_count = DeliveryBoy.objects.filter(pk=delivery_boy.id).update(
                points=F('points') - required_points,
                rewards=F('rewards') - amount_to_deduct_rewards_as_int
            )

            if updated_count == 0:
                logger.error(f"DeliveryBoy record with pk={delivery_boy.id} was NOT updated by F() expression update. This is unexpected if values were meant to change.")
            else:
                logger.info(f"DeliveryBoy record with pk={delivery_boy.id} was targeted by F() expression update (updated_count: {updated_count}).")

            # Refresh the instance from DB to reflect the changes
            delivery_boy.refresh_from_db()
            logger.info(f"After F() update and refresh_from_db - DB Points: {delivery_boy.points}, DB Rewards: {delivery_boy.rewards}")
            
            # Create notification
            DeliveryBoyNotification.objects.create(
                delivery_boy=delivery_boy,
                message=f"Voucher generated successfully for {amount} EGP. Code: {code}. Expires in 48 hours."
            )

            logger.info(f"Successfully generated voucher for {email}: {code}")
            return Response({
                'message': 'Voucher generated successfully',
                'voucher': DeliveryBoyVoucherSerializer(voucher, context={'request': request}).data,
                'remaining_points': delivery_boy.points,
                'remaining_rewards': delivery_boy.rewards
            })

    except DeliveryBoy.DoesNotExist:
        return Response({'error': 'Delivery Boy not found'}, status=404)
    except Exception as e:
        logger.error(f"Error generating voucher: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def use_delivery_boy_voucher(request, voucher_code):
    """
    Use a delivery boy voucher
    """
    try:
        voucher = DeliveryBoyVoucher.objects.get(code=voucher_code, is_used=False)
        
        # Check if voucher has expired
        if voucher.expires_at < timezone.now():
            return Response({'error': 'Voucher has expired'}, status=400)
        
        # Get branch ID from request
        branch_id = request.data.get('branch_id')
        if not branch_id:
            return Response({'error': 'Branch ID is required'}, status=400)
            
        try:
            branch = Branch.objects.get(id=branch_id)
        except Branch.DoesNotExist:
            return Response({'error': 'Invalid branch ID'}, status=404)
        
        # Mark voucher as used and save branch information
        voucher.is_used = True
        voucher.used_branch = branch
        voucher.save()
        
        # Create notification
        DeliveryBoyNotification.objects.create(
            delivery_boy=voucher.delivery_boy,
            message=f"Voucher {voucher_code} has been used successfully at {branch.name}"
        )
        
        return Response({
            'message': 'Voucher used successfully',
            'amount': voucher.amount,
            'branch': {
                'id': branch.id,
                'name': branch.name,
                'store': branch.store.name
            }
        })
    except DeliveryBoyVoucher.DoesNotExist:
        return Response({'error': 'Invalid or used voucher'}, status=404)
    except Exception as e:
        logger.error(f"Error using voucher: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def update_delivery_boy_stats(request, delivery_boy_id):
    try:
        with transaction.atomic():
            delivery_boy = DeliveryBoy.objects.get(id=delivery_boy_id)
            delivery_boy.save()  # This will automatically update points and rewards

            # Create notification for delivery boy
            DeliveryBoyNotification.objects.create(
                delivery_boy=delivery_boy,
                message=f"Your stats have been updated. Total points: {delivery_boy.points}, Rewards: {delivery_boy.rewards} EGP"
            )

            return Response({
                'message': 'Stats updated successfully',
                'points': delivery_boy.points,
                'rewards': delivery_boy.rewards
            }, status=200)
    except DeliveryBoy.DoesNotExist:
        return Response({'error': 'Delivery Boy not found'}, status=404)
    except Exception as e:
        return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def force_update_delivery_boy_rewards(request):
    try:
        DeliveryBoy.update_all_points_and_rewards()
        return Response({'message': 'Successfully updated all delivery boy rewards'}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
def redeem_delivery_points(request):
    try:
        email = request.data.get('email')
        points_to_redeem = request.data.get('points')

        if not email or not points_to_redeem:
            return Response(
                {'error': 'Email and points are required'},
                status=400
            )

        delivery_boy = DeliveryBoy.objects.filter(email=email).first()
        if not delivery_boy:
            return Response(
                {'error': 'Delivery Boy not found'},
                status=404
            )

        if delivery_boy.points < points_to_redeem:
            return Response(
                {'error': 'Insufficient points'},
                status=400
            )

        # Calculate reward amount (1 point = 0.05 EGP)
        reward_amount = points_to_redeem * 0.05

        # Update delivery boy's points and rewards
        delivery_boy.points -= points_to_redeem
        delivery_boy.rewards += reward_amount
        delivery_boy.save()

        # Create a notification
        DeliveryBoyNotification.objects.create(
            delivery_boy=delivery_boy,
            title='Points Redeemed',
            message=f'You redeemed {points_to_redeem} points for {reward_amount} EGP',
            type='reward'
        )

        return Response({
            'success': True,
            'message': 'Points redeemed successfully',
            'points_redeemed': points_to_redeem,
            'reward_amount': reward_amount,
            'remaining_points': delivery_boy.points,
            'new_balance': delivery_boy.rewards
        })
    except Exception as e:
        logger.error(f"Error redeeming points: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)        

@api_view(['GET'])
def get_order_assignment(request, order_id):
    """
    Get the assignment ID for a specific order
    """
    try:
        logger.info(f"Getting assignment for order {order_id}")
        
        # Find the recycle bag
        recycle_bag = RecycleBag.objects.get(id=order_id)
        
        # Find the latest active assignment
        assignment = DeliveryAssignment.objects.filter(
            recycle_bag=recycle_bag,
            status__in=['pending', 'accepted', 'in_transit']
        ).order_by('-assigned_at').first()

        response_data = {'id': None}  # Initialize with default values
        
        if assignment:
            logger.info(f"Found active assignment {assignment.id} for order {order_id}")
            response_data['id'] = assignment.id
            response_data['status'] = assignment.status
            
            if assignment.delivery_boy:
                response_data['delivery_boy'] = {
                    'name': f"{assignment.delivery_boy.first_name} {assignment.delivery_boy.last_name}",
                    'phone': assignment.delivery_boy.phone_number,
                    'rating': str(assignment.delivery_boy.average_rating),
                    'email': assignment.delivery_boy.email
                }
        else:
            logger.info(f"No active assignment found for order {order_id}")

        return Response(response_data)

    except RecycleBag.DoesNotExist:
        logger.error(f"Recycle bag {order_id} not found")
        return Response({
            'error': 'Order not found'
        }, status=404)
    except Exception as e:
        logger.error(f"Error getting assignment for order {order_id}: {str(e)}", exc_info=True)
        return Response({
            'error': 'An error occurred while fetching the assignment',
            'details': str(e)
        }, status=500)

@api_view(['POST'])
def create_assignment(request):
    """
    Create a new delivery assignment
    """
    try:
        logger.info("Creating new assignment")
        logger.info(f"Request data: {request.data}")

        recycle_bag_id = request.data.get('recycle_bag_id')
        delivery_boy_email = request.data.get('delivery_boy_email')

        if not recycle_bag_id:
            return Response({'error': 'recycle_bag_id is required'}, status=400)

        # Get the recycle bag
        try:
            recycle_bag = RecycleBag.objects.get(id=recycle_bag_id)
        except RecycleBag.DoesNotExist:
            logger.error(f"RecycleBag {recycle_bag_id} not found")
            return Response({'error': 'Recycle bag not found'}, status=404)

        # Check for existing active assignment
        existing_assignment = DeliveryAssignment.objects.filter(
            recycle_bag=recycle_bag,
            status__in=['pending', 'accepted', 'in_transit']
        ).first()

        if existing_assignment:
            logger.info(f"Found existing assignment {existing_assignment.id} for bag {recycle_bag_id}")
            
            # If delivery_boy_email is provided, update the assignment
            if delivery_boy_email:
                try:
                    delivery_boy = DeliveryBoy.objects.get(email=delivery_boy_email)
                    existing_assignment.delivery_boy = delivery_boy
                    existing_assignment.delivery_boy_phone = delivery_boy.phone_number
                    existing_assignment.user_phone = recycle_bag.user.phone_number
                    existing_assignment.save()
                except DeliveryBoy.DoesNotExist:
                    logger.warning(f"DeliveryBoy with email {delivery_boy_email} not found")
            
            return Response({
                'id': existing_assignment.id,
                'status': existing_assignment.status,
                'message': 'Using existing assignment'
            })

        # Create new assignment without specifying ID
        assignment = DeliveryAssignment(
            recycle_bag=recycle_bag,
            status='pending'
        )

        # If delivery_boy_email is provided, assign the delivery boy
        if delivery_boy_email:
            try:
                delivery_boy = DeliveryBoy.objects.get(email=delivery_boy_email)
                assignment.delivery_boy = delivery_boy
                assignment.delivery_boy_phone = delivery_boy.phone_number
                assignment.user_phone = recycle_bag.user.phone_number
            except DeliveryBoy.DoesNotExist:
                logger.warning(f"DeliveryBoy with email {delivery_boy_email} not found")
                # Don't return error, just log warning since delivery boy is optional at creation

        # Save the assignment
        assignment.save()

        logger.info(f"Created new assignment {assignment.id} for bag {recycle_bag_id}")
        return Response({
            'id': assignment.id,
            'status': assignment.status,
            'message': 'Assignment created successfully'
        }, status=201)

    except Exception as e:
        logger.error(f"Error creating assignment: {str(e)}", exc_info=True)
        return Response({
            'error': 'Failed to create assignment',
            'details': str(e)
        }, status=500)

@api_view(['GET'])
def get_latest_order(request, email):
    """
    Get the user's latest order
    """
    try:
        user = Register.objects.get(email=email)
        latest_order = RecycleBag.objects.filter(
            user=user
        ).order_by('-created_at').first()

        if not latest_order:
            return Response({'message': 'No orders found'}, status=404)

        serializer = RecycleBagSerializer(latest_order, context={'request': request})
        return Response(serializer.data)
    except Register.DoesNotExist:
        return Response({'error': 'User not found'}, status=404)
    except Exception as e:
        logger.error(f"Error getting latest order for {email}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def get_available_user_orders(request, email):
    """
    Get all available orders for a user
    """
    try:
        user = Register.objects.get(email=email)
        orders = RecycleBag.objects.filter(
            user=user,
            status__in=['pending', 'assigned', 'accepted', 'in_transit']
        ).order_by('-created_at')

        serializer = RecycleBagSerializer(orders, many=True, context={'request': request})
        return Response(serializer.data)
    except Register.DoesNotExist:
        return Response({'error': 'User not found'}, status=404)
    except Exception as e:
        logger.error(f"Error getting available orders for {email}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def get_user_order_status(request, email):
    """
    Get the status of a user's current order
    """
    try:
        user = Register.objects.get(email=email)
        current_order = RecycleBag.objects.filter(
            user=user,
            status__in=['pending', 'assigned', 'accepted', 'in_transit', 'delivered', 'rejected']
        ).order_by('-created_at').first()

        if not current_order:
            return Response({'message': 'No active or rejected orders found'}, status=404)

        # Get the assignment if it exists, including rejected ones to get the reason
        assignment = DeliveryAssignment.objects.filter(
            recycle_bag=current_order,
            status__in=['pending', 'accepted', 'in_transit', 'delivered', 'rejected', 'canceled']
        ).order_by('-assigned_at').first() # Get the latest assignment for this bag

        response_data = {
            'id': current_order.id,
            'status': current_order.status,
            'created_at': current_order.created_at,
            'items': [
                {
                    'type': item.item_type.name,
                    'quantity': item.quantity,
                    'points': item.points
                } for item in current_order.items.all()
            ]
        }

        if assignment: # Check if an assignment was found
            if assignment.delivery_boy:
                response_data['delivery_boy'] = {
                    'name': f"{assignment.delivery_boy.first_name} {assignment.delivery_boy.last_name}",
                    'phone': assignment.delivery_boy.phone_number,
                    'rating': str(assignment.delivery_boy.average_rating),
                    'email': assignment.delivery_boy.email
                }
            
            # If the order (RecycleBag) is rejected, and we found an assignment (which should be the rejected one)
            if current_order.status == 'rejected' and assignment.status == 'rejected' and assignment.rejection_reason:
                response_data['rejection_reason'] = assignment.rejection_reason
        
        return Response(response_data)
    except Register.DoesNotExist:
        return Response({'error': 'User not found'}, status=404)
    except Exception as e:
        logger.error(f"Error getting order status for {email}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def send_chat_message(request, assignment_id):
    """
    Send a chat message for a specific delivery assignment
    """
    try:
        assignment = DeliveryAssignment.objects.get(id=assignment_id)
        
        # Get message data from request
        message_text = request.data.get('message')
        sender_type = request.data.get('sender_type')  # 'user' or 'delivery_boy'
        # Frontend sends email as 'sender_id', so backend should expect 'sender_id'
        sender_id_from_request = request.data.get('sender_id')

        if not message_text or not sender_type or not sender_id_from_request:
            return Response({
                'error': 'Message text, sender type, and sender ID (email) are required'
            }, status=400)

        # Verify sender has permission to send message
        # Use sender_id_from_request (which is the email) for validation
        if sender_type == 'user':
            if sender_id_from_request != assignment.recycle_bag.user.email:
                return Response({'error': 'Unauthorized sender'}, status=403)
            sender = assignment.recycle_bag.user
        elif sender_type == 'delivery_boy':
            if not assignment.delivery_boy:
                 return Response({'error': 'Delivery boy not assigned to this order'}, status=400)
            if sender_id_from_request != assignment.delivery_boy.email:
                return Response({'error': 'Unauthorized sender'}, status=403)
            sender = assignment.delivery_boy
        else:
            return Response({'error': 'Invalid sender_type'}, status=400)

        # Create the message
        # ChatMessage model expects 'sender_id' which will store the email string
        message = ChatMessage.objects.create(
            assignment=assignment,
            sender_type=sender_type,
            sender_id=sender_id_from_request, # Pass the email as sender_id
            message=message_text
        )

        # Create notifications
        if sender_type == 'user' and assignment.delivery_boy:
            # Notify delivery boy
            DeliveryBoyNotification.objects.create(
                delivery_boy=assignment.delivery_boy,
                message=f"New message from {sender.first_name if hasattr(sender, 'first_name') else 'user'}: {message_text[:50]}..."
            )
        elif sender_type == 'delivery_boy':
            # Notify user
            Notification.objects.create(
                user=assignment.recycle_bag.user,
                message=f"New message from {sender.first_name if hasattr(sender, 'first_name') else 'delivery boy'}: {message_text[:50]}..."
            )

        return Response({
            'id': message.id,
            'message': message.message,
            'sender_type': message.sender_type,
            'sender_id': message.sender_id, # Return sender_id as it's stored
            'created_at': message.created_at.isoformat()
        }, status=201)

    except DeliveryAssignment.DoesNotExist:
        return Response({'error': 'Assignment not found'}, status=404)
    except Exception as e:
        logger.error(f"Error sending chat message: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def get_chat_messages(request, assignment_id):
    """
    Get all chat messages for a specific delivery assignment
    """
    try:
        assignment = DeliveryAssignment.objects.get(id=assignment_id)
        
        # Get requester email from query params
        requester_email = request.query_params.get('email')
        if not requester_email:
            return Response({'error': 'Requester email is required'}, status=400)

        # Verify requester has permission to view messages
        if requester_email not in [
            assignment.recycle_bag.user.email,
            assignment.delivery_boy.email if assignment.delivery_boy else None
        ]:
            return Response({'error': 'Unauthorized to view these messages'}, status=403)

        # Get all messages for this assignment
        messages = ChatMessage.objects.filter(assignment=assignment).order_by('created_at')
        
        messages_data = [{
            'id': message.id,
            'message': message.message,
            'sender_type': message.sender_type,
            'sender_id': message.sender_id,
            'created_at': message.created_at
        } for message in messages]

        return Response(messages_data, content_type='application/json; charset=utf-8')

    except DeliveryAssignment.DoesNotExist:
        return Response({'error': 'Assignment not found'}, status=404)
    except Exception as e:
        logger.error(f"Error getting chat messages: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def rate_order(request, assignment_id):
    """
    Rate a delivery order by the user who placed the order.
    """
    try:
        with transaction.atomic():
            logger.info(f"Rating order for assignment {assignment_id}")
            logger.info(f"Request data: {request.data}")

            assignment = get_object_or_404(DeliveryAssignment.objects.select_related('recycle_bag', 'delivery_boy', 'recycle_bag__user'), id=assignment_id)

            if not assignment.delivery_boy:
                logger.error(f"No delivery boy assigned to assignment {assignment_id}")
                return Response({'error': 'No delivery boy assigned to this order.'}, status=400)

            rating_user = assignment.recycle_bag.user
            delivery_boy_to_rate = assignment.delivery_boy
            recycle_bag_context = assignment.recycle_bag

            stars_input = request.data.get('stars')
            comment = request.data.get('comment', '')

            if stars_input is None:
                logger.error("No rating (stars) provided for assignment {assignment_id}")
                return Response({'error': 'Rating (stars) is required'}, status=400)
            
            try:
                stars = int(stars_input)
                if not (1 <= stars <= 5): # Assuming a 1-5 star rating
                    raise ValueError("Rating must be between 1 and 5.")
            except ValueError as e:
                logger.error(f"Invalid rating value: {stars_input} for assignment {assignment_id}. Error: {e}")
                return Response({'error': f'Invalid rating value: {str(e)}'}, status=400)

            rating_obj, created = DeliveryBoyRating.objects.update_or_create(
                recycle_bag=recycle_bag_context,
                delivery_boy=delivery_boy_to_rate,
                user=rating_user,
                defaults={'user_rating': stars, 'user_comment': comment}
            )

            logger.info(f"{'Created' if created else 'Updated'} rating for delivery_boy {delivery_boy_to_rate.id} (bag {recycle_bag_context.id}) by user {rating_user.id}. Stars: {stars}")

            all_ratings_for_boy = DeliveryBoyRating.objects.filter(delivery_boy=delivery_boy_to_rate)
            
            if all_ratings_for_boy.exists():
                new_average_rating = all_ratings_for_boy.aggregate(Avg('user_rating'))['user_rating__avg']
                delivery_boy_to_rate.average_rating = round(new_average_rating, 2) if new_average_rating is not None else 0.0
            else:
                delivery_boy_to_rate.average_rating = 0.0 # Should be stars if this is the first rating
            
            delivery_boy_to_rate.save()
            logger.info(f"Updated average rating for delivery boy {delivery_boy_to_rate.id} to {delivery_boy_to_rate.average_rating}")

            return Response({
                'message': 'Order rated successfully',
                'rating_id': rating_obj.id,
                'delivery_boy_average_rating': delivery_boy_to_rate.average_rating
            }, status=201 if created else 200)

    except DeliveryAssignment.DoesNotExist:
        logger.error(f"Assignment {assignment_id} not found for rating")
        return Response({'error': 'Assignment not found'}, status=404)
    except Exception as e:
        logger.error(f"Error rating order for assignment {assignment_id}: {str(e)}", exc_info=True)
        return Response({'error': f'An error occurred while rating the order: {str(e)}'}, status=500)

@api_view(['GET'])
def get_delivery_boy_vouchers(request, email):
    """Get all vouchers for a delivery boy"""
    try:
        delivery_boy = DeliveryBoy.objects.get(email=email)
        vouchers = DeliveryBoyVoucher.objects.filter(delivery_boy=delivery_boy).order_by('-created_at')
        return Response(DeliveryBoyVoucherSerializer(vouchers, many=True).data)
    except DeliveryBoy.DoesNotExist:
        return Response({'error': 'Delivery Boy not found'}, status=404)
    except Exception as e:
        logger.error(f"Error fetching vouchers: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def check_delivery_boy_voucher_status(request, email):
    """Check if a delivery boy has an active voucher"""
    try:
        delivery_boy = DeliveryBoy.objects.get(email=email)
        active_voucher = DeliveryBoyVoucher.objects.filter(
            delivery_boy=delivery_boy,
            is_used=False,
            expires_at__gt=timezone.now()
        ).first()
        
        if active_voucher:
            return Response({
                'has_active_voucher': True,
                'active_voucher': DeliveryBoyVoucherSerializer(active_voucher).data
            })
        else:
            return Response({
                'has_active_voucher': False,
                'message': 'No active voucher found'
            })
    except DeliveryBoy.DoesNotExist:
        return Response({'error': 'Delivery Boy not found'}, status=404)
    except Exception as e:
        logger.error(f"Error checking voucher status: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def get_delivery_boy_balance(request, email):
    """
    Get delivery boy's points and rewards
    """
    try:
        delivery_boy = DeliveryBoy.objects.get(email=email)
        
        # Calculate total points and rewards
        total_points = delivery_boy.points
        total_voucher_amount = CustomerVoucher.objects.filter(
            delivery_boy=delivery_boy,
            is_used=True
        ).aggregate(total=Sum('amount'))['total'] or 0

        # Get last activity details
        last_activity = Activity.objects.filter(
            user__email=email
        ).order_by('-date').first()

        last_activity_details = {
            'title': last_activity.title if last_activity else None,
            'points': last_activity.points if last_activity else 0,
            'date': last_activity.date if last_activity else None
        }

        # Calculate rewards (10 EGP for every 100 points)
        rewards = (total_points // 100) * 10

        response_data = {
            'points': total_points,
            'rewards': rewards,
            'last_activity': last_activity_details
        }

        logger.info(f"Fetched balance for {email}: points={total_points}, rewards={rewards}, last_activity={last_activity_details}")
        return Response(response_data)

    except DeliveryBoy.DoesNotExist:
        logger.error(f"Delivery boy not found with email: {email}")
        return Response({'error': 'Delivery boy not found'}, status=404)
    except Exception as e:
        logger.error(f"Error fetching balance for {email}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def create_pending_bag(request):
    """
    Create a new pending recycling bag
    """
    try:
        email = request.data.get('email')
        items = request.data.get('items', [])

        user = get_object_or_404(Register, email=email)
        bag = RecycleBag.objects.create(user=user, status='pending')

        points_per_unit = {
            'Plastic Bottle': 5,
            'Glass Bottle': 8,
            'Aluminum Can': 10
        }

        for item in items:
            item_type = ItemType.objects.filter(id=item['item_type']).first()
            if not item_type:
                logger.error(f"Invalid item type ID: {item['item_type']}")
                continue
            if item_type.name not in points_per_unit:
                logger.error(f"Invalid item type: {item_type.name}")
                continue
            points = points_per_unit[item_type.name] * item['quantity']
            if points < 0:
                logger.error(f"Negative points calculated for item {item_type.name}")
                continue
            RecycleBagItem.objects.create(
                bag=bag,
                item_type=item_type,
                quantity=item['quantity'],
                points=points
            )

        # تأكيد استدعاء الدالة وتسجيل النتيجة
        assignment_success = assign_order_to_delivery_boy(bag)
        if not assignment_success:
            logger.warning(f"Failed to assign order {bag.id} to delivery boys")
        else:
            logger.info(f"Successfully assigned order {bag.id} to delivery boys")

        logger.info(f"Created pending bag for {email} with {len(items)} items")
        return Response({'message': 'Recycling bag created successfully'}, status=201)
    except Exception as e:
        logger.error(f"Error in create_pending_bag for {email}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def update_order_status(request, bag_id):
    """
    Update the status of a recycle bag
    """
    try:
        bag = get_object_or_404(RecycleBag, id=bag_id)
        data = request.data
        status = data.get('status')
        
        if status not in ['pending', 'confirmed', 'delivered', 'rejected']:
            return Response({'error': 'Invalid status'}, status=400)

        bag.status = status
        bag.save()

        # تسجيل نشاط جديد بناءً على الحالة
        user = bag.user
        if status == 'delivered':
            Activity.objects.create(
                user=user,
                title=f"Order {bag.id} Delivered",
                points=0,
                type="delivered"
            )
        elif status == 'rejected':
            Activity.objects.create(
                user=user,
                title=f"Order {bag.id} Rejected",
                points=0,
                type="rejected"
            )

        serializer = RecycleBagSerializer(bag)
        return Response(serializer.data)

    except Exception as e:
        logger.error(f"Error updating order {bag_id}: {str(e)}", exc_info=True)
        return Response({'error': str(e)}, status=500)