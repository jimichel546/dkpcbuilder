from django.db import migrations, models


def clear_reviews_without_image(apps, schema_editor):
    Review = apps.get_model('shop', 'Review')
    Review.objects.all().delete()


class Migration(migrations.Migration):

    dependencies = [
        ('shop', '0002_galleryphoto_review_build_cpu_brand_build_is_active'),
    ]

    operations = [
        migrations.RunPython(clear_reviews_without_image, migrations.RunPython.noop),
        migrations.AddField(
            model_name='review',
            name='image',
            field=models.ImageField(upload_to='reviews/', verbose_name='Фото'),
        ),
    ]
