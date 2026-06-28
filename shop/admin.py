from django.contrib import admin

from .models import Build, GalleryPhoto, Order, Review


@admin.action(description='Отметить как обработанные')
def mark_as_processed(modeladmin, request, queryset):
    queryset.update(is_processed=True)


@admin.register(Build)
class BuildAdmin(admin.ModelAdmin):
    list_display = ('name', 'category', 'cpu_brand', 'price', 'is_popular', 'is_active')
    list_filter = ('category', 'cpu_brand', 'is_popular', 'is_active')
    prepopulated_fields = {'slug': ('name',)}


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ('name', 'contact', 'budget', 'purpose', 'is_processed', 'created_at')
    list_filter = ('is_processed', 'purpose')
    actions = [mark_as_processed]
    readonly_fields = ('created_at',)


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ('author', 'rating', 'is_published', 'created_at')
    list_editable = ('is_published',)
    list_filter = ('rating', 'is_published')


@admin.register(GalleryPhoto)
class GalleryPhotoAdmin(admin.ModelAdmin):
    list_display = ('caption', 'order')
    list_editable = ('order',)
