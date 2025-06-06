# Generated by Django 5.2 on 2025-04-26 19:15

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("api", "0006_register_voucher_expiry_alter_branch_governorate_and_more"),
    ]

    operations = [
        migrations.RemoveField(
            model_name="recyclebag",
            name="latitude",
        ),
        migrations.RemoveField(
            model_name="recyclebag",
            name="longitude",
        ),
        migrations.RemoveField(
            model_name="register",
            name="latitude",
        ),
        migrations.RemoveField(
            model_name="register",
            name="longitude",
        ),
        migrations.AlterField(
            model_name="branch",
            name="governorate",
            field=models.CharField(
                blank=True,
                choices=[
                    ("alexandria", "Alexandria"),
                    ("aswan", "Aswan"),
                    ("asyut", "Asyut"),
                    ("beheira", "Beheira"),
                    ("beni_suef", "Beni Suef"),
                    ("cairo", "Cairo"),
                    ("dakahlia", "Dakahlia"),
                    ("damietta", "Damietta"),
                    ("faiyum", "Faiyum"),
                    ("gharbia", "Gharbia"),
                    ("giza", "Giza"),
                    ("ismailia", "Ismailia"),
                    ("kafr_el_sheikh", "Kafr El Sheikh"),
                    ("luxor", "Luxor"),
                    ("matruh", "Matruh"),
                    ("minya", "Minya"),
                    ("monufia", "Monufia"),
                    ("new_valley", "New Valley"),
                    ("north_sinai", "North Sinai"),
                    ("port_said", "Port Said"),
                    ("qalyubia", "Qalyubia"),
                    ("qena", "Qena"),
                    ("red_sea", "Red Sea"),
                    ("sharqia", "Sharqia"),
                    ("sohag", "Sohag"),
                    ("south_sinai", "South Sinai"),
                    ("suez", "Suez"),
                ],
                max_length=100,
                null=True,
            ),
        ),
        migrations.AlterField(
            model_name="recyclebag",
            name="status",
            field=models.CharField(
                choices=[("pending", "Pending"), ("completed", "Completed")],
                default="pending",
                max_length=10,
            ),
        ),
    ]
