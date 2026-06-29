(function () {
    'use strict';

    /* Header scroll + burger */
    const header = document.querySelector('.site-header');
    const burger = document.querySelector('.burger');
    const navMobile = document.querySelector('.nav-mobile');

    if (header) {
        window.addEventListener('scroll', function () {
            header.classList.toggle('scrolled', window.scrollY > 20);
        }, { passive: true });
        header.classList.toggle('scrolled', window.scrollY > 20);
    }

    if (burger && navMobile) {
        burger.addEventListener('click', function () {
            burger.classList.toggle('active');
            navMobile.classList.toggle('open');
            document.body.style.overflow = navMobile.classList.contains('open') ? 'hidden' : '';
        });

        navMobile.querySelectorAll('a').forEach(function (link) {
            link.addEventListener('click', function () {
                burger.classList.remove('active');
                navMobile.classList.remove('open');
                document.body.style.overflow = '';
            });
        });
    }

    /* Lightbox */
    const lightbox = document.getElementById('lightbox');
    if (lightbox) {
        const lbImg = lightbox.querySelector('img');
        const lbCaption = lightbox.querySelector('.lightbox-caption');
        const lbClose = lightbox.querySelector('.lightbox-close');

        document.querySelectorAll('[data-lightbox]').forEach(function (item) {
            item.addEventListener('click', function () {
                lbImg.src = item.dataset.lightbox;
                lbCaption.textContent = item.dataset.caption || '';
                lightbox.classList.add('open');
                document.body.style.overflow = 'hidden';
            });
        });

        function closeLightbox() {
            lightbox.classList.remove('open');
            document.body.style.overflow = '';
        }

        lbClose.addEventListener('click', closeLightbox);
        lightbox.addEventListener('click', function (e) {
            if (e.target === lightbox) closeLightbox();
        });
        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape') closeLightbox();
        });
    }

    /* Order forms (build detail + contact) */
    function bindAjaxOrderForm(form, errorEl, successEl, successMessage) {
        form.addEventListener('submit', function (e) {
            e.preventDefault();
            errorEl.style.display = 'none';
            successEl.style.display = 'none';

            const submitBtn = form.querySelector('[type="submit"]');
            const btnText = submitBtn.textContent;
            submitBtn.disabled = true;
            submitBtn.textContent = 'Отправка…';

            const payload = Object.fromEntries(new FormData(form).entries());
            const csrfToken = window.getCsrfToken();

            if (!csrfToken) {
                errorEl.textContent = 'Ошибка безопасности. Обновите страницу и попробуйте снова.';
                errorEl.style.display = 'block';
                submitBtn.disabled = false;
                submitBtn.textContent = btnText;
                return;
            }

            fetch(form.action, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': csrfToken,
                    'X-Requested-With': 'XMLHttpRequest',
                },
                body: JSON.stringify(payload),
            })
            .then(function (res) {
                const contentType = res.headers.get('Content-Type') || '';
                if (contentType.includes('application/json')) {
                    return res.json().then(function (data) {
                        return { ok: res.ok, data: data };
                    });
                }
                return { ok: false, data: { errors: { __all__: ['Ошибка сервера. Обновите страницу.'] } } };
            })
            .then(function (result) {
                if (result.ok && result.data.status === 'ok') {
                    successEl.textContent = successMessage;
                    successEl.style.display = 'block';
                    form.reset();
                } else {
                    const errors = result.data.errors;
                    let msg = 'Ошибка отправки.';
                    if (errors) {
                        msg = Object.values(errors).flat().join(' ');
                    }
                    errorEl.textContent = msg;
                    errorEl.style.display = 'block';
                }
            })
            .catch(function () {
                errorEl.textContent = 'Не удалось отправить заявку.';
                errorEl.style.display = 'block';
            })
            .finally(function () {
                submitBtn.disabled = false;
                submitBtn.textContent = btnText;
            });
        });
    }

    const orderForm = document.getElementById('build-order-form');
    if (orderForm) {
        bindAjaxOrderForm(
            orderForm,
            document.getElementById('order-form-error'),
            document.getElementById('order-form-success'),
            'Заявка отправлена! Мы свяжемся с вами.'
        );
    }

    const contactForm = document.getElementById('contact-form');
    if (contactForm) {
        bindAjaxOrderForm(
            contactForm,
            document.getElementById('contact-form-error'),
            document.getElementById('contact-form-success'),
            'Спасибо! Мы свяжемся с вами в ближайшее время.'
        );
    }

})();
