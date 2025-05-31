from django.db import migrations

class Migration(migrations.Migration):

    dependencies = [
        ('api', '0023_rename_balance_deliveryboy_voucher_amount_and_more'),
    ]

    operations = [
        migrations.DeleteModel(
            name='DeliveryBoyReward',
        ),
    ] 