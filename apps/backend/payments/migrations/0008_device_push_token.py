from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('payments', '0007_phase3_financial_platform'),
    ]

    operations = [
        migrations.AddField(
            model_name='device',
            name='push_token',
            field=models.CharField(blank=True, default='', max_length=255),
        ),
    ]
