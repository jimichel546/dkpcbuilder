from django.conf import settings

from .seo import canonical_url, is_primary_host


def seo(request):
    primary = settings.SITE_URL.rstrip('/')
    path = request.path

    return {
        'site_url': primary,
        'site_domain': settings.SITE_DOMAIN,
        'canonical_url': canonical_url(path),
        'seo_robots': 'index, follow' if is_primary_host(request) else 'noindex, follow',
        'default_meta_description': settings.DEFAULT_META_DESCRIPTION,
        'google_site_verification': settings.GOOGLE_SITE_VERIFICATION,
        'yandex_verification': settings.YANDEX_VERIFICATION,
        'contact_telegram_url': settings.CONTACT_TELEGRAM_URL,
        'contact_telegram_label': settings.CONTACT_TELEGRAM_LABEL,
        'contact_kufar_url': settings.CONTACT_KUFAR_URL,
        'contact_kufar_label': settings.CONTACT_KUFAR_LABEL,
    }
