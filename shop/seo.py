from django.conf import settings


def is_primary_host(request) -> bool:
    host = request.get_host().split(':')[0].lower()
    primary = settings.SITE_DOMAIN.lower()
    return host in {primary, f'www.{primary}'}


def canonical_url(path: str) -> str:
    base = settings.SITE_URL.rstrip('/')
    if not path.startswith('/'):
        path = f'/{path}'
    return f'{base}{path}'


def absolute_media_url(relative_url: str) -> str:
    if not relative_url:
        return ''
    if relative_url.startswith('http'):
        return relative_url
    return f'{settings.SITE_URL.rstrip("/")}{relative_url}'
