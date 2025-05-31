import os
import django
from django.db import transaction, models

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'back.settings')
django.setup()

from api.models import DeliveryAssignment, RecycleBag

def clean_duplicate_assignments():
    try:
        with transaction.atomic():
            # الحصول على جميع الطلبات التي لديها تعيينات متعددة
            bags_with_multiple_assignments = RecycleBag.objects.filter(
                id__in=DeliveryAssignment.objects.values('recycle_bag')
                .annotate(count=models.Count('id'))
                .filter(count__gt=1)
                .values('recycle_bag')
            )

            cleaned_count = 0
            for bag in bags_with_multiple_assignments:
                # الحصول على جميع التعيينات للطلب
                assignments = DeliveryAssignment.objects.filter(recycle_bag=bag).order_by('-assigned_at')
                
                # الاحتفاظ بأحدث تعيين فقط
                latest_assignment = assignments.first()
                assignments.exclude(id=latest_assignment.id).delete()
                
                cleaned_count += 1
                print(f"Cleaned assignments for bag {bag.id}")

            print(f"Successfully cleaned {cleaned_count} bags with duplicate assignments")

    except Exception as e:
        print(f"Error cleaning assignments: {str(e)}")

if __name__ == "__main__":
    clean_duplicate_assignments() 