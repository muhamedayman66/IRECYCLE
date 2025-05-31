import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'back.settings')
django.setup()

from api.models import RecycleBag, DeliveryAssignment, DeliveryBoy

def fix_orders():
    try:
        # Get the pending bag
        bag = RecycleBag.objects.get(user__email='hadeerhamm2313@gmail.com')
        print(f'Found bag with status: {bag.status}')
        
        # Reset bag status to pending
        bag.status = 'pending'
        bag.save()
        print('Updated bag status to pending')
        
        # Delete any existing assignments
        deleted = DeliveryAssignment.objects.filter(recycle_bag=bag).delete()
        print(f'Deleted {deleted[0]} existing assignments')
        
        # Create new assignment
        assignment = DeliveryAssignment.objects.create(
            recycle_bag=bag,
            status='pending'
        )
        print(f'Created new assignment with ID: {assignment.id}')
        
        print('Fix completed successfully')
        
    except Exception as e:
        print(f'Error: {str(e)}')

if __name__ == '__main__':
    fix_orders() 