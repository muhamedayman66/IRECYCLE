# Generated by Django 5.2 on 2025-05-15 03:26

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("api", "0028_alter_deliveryassignment_options_and_more"),
    ]

    operations = [
        migrations.AlterField(
            model_name="chatmessage",
            name="sender_id",
            field=models.CharField(max_length=255),
        ),
    ]
