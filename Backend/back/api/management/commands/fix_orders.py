from django.core.management.base import BaseCommand
from api.models import RecycleBag, DeliveryAssignment, DeliveryBoy

class Command(BaseCommand):
    help = 'Fix orders and assignments'

    def handle(self, *args, **options):
        try:
            # Get the pending bag
            bag = RecycleBag.objects.get(user__email='hadeerhamm2313@gmail.com')
            self.stdout.write(f'Found bag with status: {bag.status}')
            
            # Reset bag status to pending
            bag.status = 'pending'
            bag.save()
            self.stdout.write('Updated bag status to pending')
            
            # Delete any existing assignments
            deleted = DeliveryAssignment.objects.filter(recycle_bag=bag).delete()
            self.stdout.write(f'Deleted {deleted[0]} existing assignments')
            
            # Create new assignment
            assignment = DeliveryAssignment.objects.create(
                recycle_bag=bag,
                status='pending'
            )
            self.stdout.write(f'Created new assignment with ID: {assignment.id}')
            
            self.stdout.write(self.style.SUCCESS('Fix completed successfully'))
            
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Error: {str(e)}')) 