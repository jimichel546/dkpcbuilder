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

    /* Order form (build detail) */
    const orderForm = document.getElementById('build-order-form');
    if (orderForm) {
        orderForm.addEventListener('submit', function (e) {
            e.preventDefault();
            const errorEl = document.getElementById('order-form-error');
            const successEl = document.getElementById('order-form-success');
            errorEl.style.display = 'none';
            successEl.style.display = 'none';

            const formData = new FormData(orderForm);
            const payload = Object.fromEntries(formData.entries());

            fetch(orderForm.action, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': getCookie('csrftoken'),
                    'X-Requested-With': 'XMLHttpRequest',
                },
                body: JSON.stringify(payload),
            })
            .then(function (res) {
                return res.json().then(function (data) {
                    return { ok: res.ok, data: data };
                });
            })
            .then(function (result) {
                if (result.ok && result.data.status === 'ok') {
                    successEl.textContent = 'Заявка отправлена! Мы свяжемся с вами.';
                    successEl.style.display = 'block';
                    orderForm.reset();
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
            });
        });
    }

    function getCookie(name) {
        const match = document.cookie.match(new RegExp('(^| )' + name + '=([^;]+)'));
        return match ? decodeURIComponent(match[2]) : null;
    }
})();
