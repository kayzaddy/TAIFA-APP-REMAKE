from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('trips', '0023_brt_phase8_lost_found'),
    ]

    operations = [
        migrations.AddField(
            model_name='transitlostfounditem',
            name='photo_url',
            field=models.URLField(blank=True, default='', max_length=500),
        ),
    ]
