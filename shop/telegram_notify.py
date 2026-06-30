import logging
import threading
import time

import requests
from django.conf import settings

from .models import Order

logger = logging.getLogger(__name__)

_session = requests.Session()
_session_lock = threading.Lock()

MAX_ATTEMPTS = 4
CONNECT_TIMEOUT = 15
READ_TIMEOUT = 20


def _is_configured() -> bool:
    token = settings.TELEGRAM_BOT_TOKEN
    chat_id = settings.TELEGRAM_CHAT_ID
    return bool(token and chat_id and chat_id != 'your-chat-id')


def build_order_message(order: Order) -> str:
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
    return text


def _send_message(text: str, order_id: int) -> bool:
    if not _is_configured():
        logger.warning(
            'Telegram не настроен: проверьте TELEGRAM_BOT_TOKEN и TELEGRAM_CHAT_ID в .env'
        )
        return False

    token = settings.TELEGRAM_BOT_TOKEN
    chat_id = settings.TELEGRAM_CHAT_ID
    url = f'https://api.telegram.org/bot{token}/sendMessage'
    payload = {'chat_id': chat_id, 'text': text}

    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            with _session_lock:
                response = _session.post(
                    url,
                    json=payload,
                    timeout=(CONNECT_TIMEOUT, READ_TIMEOUT),
                )
            response.raise_for_status()
            return True
        except requests.RequestException as exc:
            logger.warning(
                'Telegram: попытка %s/%s для заявки #%s не удалась: %s',
                attempt,
                MAX_ATTEMPTS,
                order_id,
                exc.__class__.__name__,
            )
            if hasattr(exc, 'response') and exc.response is not None:
                logger.warning('Telegram API ответ (заявка #%s): %s', order_id, exc.response.text)
            if attempt < MAX_ATTEMPTS:
                time.sleep(attempt * 2)

    logger.error('Telegram: все попытки исчерпаны для заявки #%s', order_id)
    return False


def schedule_telegram_notification(order: Order) -> None:
    """Отправляет уведомление в фоне, не блокируя ответ пользователю."""
    if not _is_configured():
        logger.warning(
            'Telegram не настроен: проверьте TELEGRAM_BOT_TOKEN и TELEGRAM_CHAT_ID в .env'
        )
        return

    text = build_order_message(order)
    thread = threading.Thread(
        target=_send_message,
        args=(text, order.pk),
        daemon=True,
        name=f'telegram-order-{order.pk}',
    )
    thread.start()
