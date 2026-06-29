from django.contrib.sitemaps import Sitemap
from django.urls import reverse

from .models import Build


class StaticViewSitemap(Sitemap):
    changefreq = 'weekly'
    priority = 0.8

    def items(self):
        return ['index', 'catalog', 'privacy', 'terms', 'cookies']

    def location(self, item):
        return reverse(item)


class BuildSitemap(Sitemap):
    changefreq = 'weekly'
    priority = 0.9

    def items(self):
        return Build.objects.filter(is_active=True)

    def lastmod(self, obj):
        return obj.created_at

    def location(self, obj):
        return reverse('build_detail', kwargs={'slug': obj.slug})
