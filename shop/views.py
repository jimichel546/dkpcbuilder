import json
import logging

import requests
from django.conf import settings
from django.http import HttpResponse, JsonResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.views.decorators.csrf import ensure_csrf_cookie
from django.views.decorators.http import require_POST

from .forms import BuildOrderForm, ContactForm, OrderForm
from .models import Build, GalleryPhoto, Order, Review
from .seo import absolute_media_url

logger = logging.getLogger(__name__)


def robots_txt(request):
    sitemap_url = f'{settings.SITE_URL.rstrip("/")}/sitemap.xml'
    content = '\n'.join([
        'User-agent: *',
        'Allow: /',
        'Disallow: /admin/',
        'Disallow: /order/',
        'Disallow: /success/',
        f'Sitemap: {sitemap_url}',
        '',
    ])
    return HttpResponse(content, content_type='text/plain; charset=utf-8')


def send_telegram_notification(order: Order) -> bool:
    token = settings.TELEGRAM_BOT_TOKEN
    chat_id = settings.TELEGRAM_CHAT_ID

    if not token or not chat_id or chat_id == 'your-chat-id':
        logger.warning(
            'Telegram не настроен: проверьте TELEGRAM_BOT_TOKEN и TELEGRAM_CHAT_ID в .env'
        )
        return False

    build_name = order.build.name if order.build else 'Не выбрана'
    if order.build:
        text = (
            f'🖥 Заявка на сборку «{build_name}»\n\n'
            f'👤 Имя: {order.name}\n'
            f'📞 Контакт: {order.contact}\n'
        )
    else:
        text = (
            f'🖥 Новая заявка на сборку ПК\n\n'
            f'👤 Имя: {order.name}\n'
            f'📞 Контакт: {order.contact}\n'
            f'💰 Бюджет: {order.get_budget_display()}\n'
            f'🎯 Цель: {order.get_purpose_display()}\n'
            f'📦 Сборка: {build_name}\n'
        )
    if order.comment:
        text += f'\n💬 Комментарий:\n{order.comment}'

    url = f'https://api.telegram.org/bot{token}/sendMessage'
    try:
        response = requests.post(
            url,
            json={'chat_id': chat_id, 'text': text},
            timeout=10,
        )
        response.raise_for_status()
        return True
    except requests.RequestException as exc:
        logger.error('Ошибка отправки в Telegram: %s', exc)
        if hasattr(exc, 'response') and exc.response is not None:
            logger.error('Ответ Telegram API: %s', exc.response.text)
        return False


def _is_ajax(request):
    content_type = request.headers.get('Content-Type', '')
    return (
        request.headers.get('X-Requested-With') == 'XMLHttpRequest'
        or content_type == 'application/json'
        or content_type.startswith('application/json')
    )


def _order_form_class(data):
    if data.get('build'):
        return BuildOrderForm
    if 'budget' in data or 'purpose' in data:
        return OrderForm
    return ContactForm


@ensure_csrf_cookie
def index(request):
    builds = Build.objects.filter(is_active=True)[:6]
    reviews = Review.objects.filter(is_published=True)[:6]
    photos = GalleryPhoto.objects.order_by('order')[:9]
    prefill_build = None
    build_slug = request.GET.get('build', '')
    if build_slug:
        prefill_build = Build.objects.filter(slug=build_slug, is_active=True).first()
    return render(request, 'shop/index.html', {
        'builds': builds,
        'reviews': reviews,
        'photos': photos,
        'prefill_build': prefill_build,
        'contact_form': ContactForm(),
    })


def catalog(request):
    builds = Build.objects.filter(is_active=True)
    cpu_filter = request.GET.get('cpu', '')
    if cpu_filter in ('intel', 'amd'):
        builds = builds.filter(cpu_brand=cpu_filter)
    return render(request, 'shop/catalog.html', {
        'builds': builds,
        'cpu_filter': cpu_filter,
    })


@ensure_csrf_cookie
def build_detail(request, slug):
    build = get_object_or_404(Build, slug=slug, is_active=True)
    og_image = absolute_media_url(build.image.url) if build.image else ''
    return render(request, 'shop/build_detail.html', {
        'build': build,
        'og_image': og_image,
    })


def static_page(request, page):
    return render(request, f'shop/legal/{page}.html', {'page': page})


@require_POST
def submit_order(request):
    if _is_ajax(request):
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({'status': 'error', 'errors': {'__all__': ['Неверный JSON']}}, status=400)

        form_class = _order_form_class(data)
        form = form_class(data)
        if form.is_valid():
            order = form.save()
            send_telegram_notification(order)
            return JsonResponse({'status': 'ok'})
        return JsonResponse({'status': 'error', 'errors': form.errors}, status=400)

    form_class = _order_form_class(request.POST)
    form = form_class(request.POST)
    if form.is_valid():
        order = form.save()
        send_telegram_notification(order)
        return redirect('quiz_success')
    return render(request, 'shop/index.html', {
        'builds': Build.objects.filter(is_active=True)[:6],
        'reviews': Review.objects.filter(is_published=True)[:6],
        'photos': GalleryPhoto.objects.order_by('order')[:9],
        'prefill_build': None,
        'contact_form': ContactForm(),
    }, status=400)


def quiz_success(request):
    return render(request, 'shop/quiz_success.html')
