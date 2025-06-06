# Generated by Django 5.2 on 2025-05-13 08:08

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0022_deliveryboy_balance_deliveryboy_last_activity_and_more'),
    ]

    operations = [
        migrations.RenameField(
            model_name='deliveryboy',
            old_name='balance',
            new_name='voucher_amount',
        ),
        migrations.RemoveField(
            model_name='deliveryboy',
            name='last_activity',
        ),
        migrations.AddField(
            model_name='deliveryboy',
            name='rewards',
            field=models.IntegerField(default=0),
        ),
        migrations.AddField(
            model_name='deliveryboy',
            name='voucher_expiry',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AlterField(
            model_name='deliveryboy',
            name='points',
            field=models.IntegerField(default=0),
        ),
        migrations.AlterField(
            model_name='deliveryboyreward',
            name='delivery_boy',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='reward_records', to='api.deliveryboy'),
        ),
    ]
