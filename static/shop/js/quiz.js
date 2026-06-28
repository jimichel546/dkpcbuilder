(function () {
    'use strict';

    const quizSection = document.getElementById('quiz-app');
    if (!quizSection) return;

    const RECOMMENDATIONS = {
        games: {
            up_to_500: { name: 'Игровой старт', price: '1850 BYN', description: 'Комфортный Full HD в популярных играх', cpu: 'Ryzen 5 5600', gpu: 'GTX 1660 Super', ram: '16 GB DDR4', storage: '512 GB SSD' },
            '500_800': { name: 'Игровой баланс', price: '2650 BYN', description: '1080p Ultra / 1440p High', cpu: 'Ryzen 5 7600', gpu: 'RTX 4060', ram: '16 GB DDR5', storage: '1 TB SSD' },
            '800_1200': { name: 'Игровой Pro', price: '3850 BYN', description: '1440p Ultra, высокий FPS в AAA', cpu: 'Ryzen 7 7700X', gpu: 'RTX 4070 Super', ram: '32 GB DDR5', storage: '1 TB NVMe' },
            '1200_plus': { name: 'Игровой Ultra', price: '5200 BYN', description: '4K-гейминг и стрим', cpu: 'Ryzen 7 7800X3D', gpu: 'RTX 4080 Super', ram: '32 GB DDR5', storage: '2 TB NVMe' },
        },
        work: {
            up_to_500: { name: 'Офисный базовый', price: '1450 BYN', description: 'Документы, браузер, видеозвонки', cpu: 'Intel i3-12100', gpu: 'Intel UHD 730', ram: '16 GB DDR4', storage: '512 GB SSD' },
            '500_800': { name: 'Рабочая станция', price: '2350 BYN', description: 'Монтаж, дизайн, многозадачность', cpu: 'Ryzen 5 7600', gpu: 'RTX 4060', ram: '32 GB DDR5', storage: '1 TB SSD' },
            '800_1200': { name: 'Рабочий Pro', price: '3600 BYN', description: '3D, рендер, тяжёлые нагрузки', cpu: 'Ryzen 7 7700X', gpu: 'RTX 4070', ram: '64 GB DDR5', storage: '2 TB NVMe' },
            '1200_plus': { name: 'Рабочий Ultra', price: '5800 BYN', description: 'Профессиональный рендер', cpu: 'Ryzen 9 7900X', gpu: 'RTX 4080 Super', ram: '64 GB DDR5', storage: '2 TB NVMe' },
        },
        study: {
            up_to_500: { name: 'Учебный Lite', price: '1200 BYN', description: 'Лекции, браузер, офис', cpu: 'Ryzen 5 5500', gpu: 'GTX 1650', ram: '8 GB DDR4', storage: '256 GB SSD' },
            '500_800': { name: 'Учебный Plus', price: '1950 BYN', description: 'Программирование, лёгкий дизайн', cpu: 'Ryzen 5 5600', gpu: 'RTX 3050', ram: '16 GB DDR4', storage: '512 GB SSD' },
            '800_1200': { name: 'Учебный Pro', price: '2900 BYN', description: 'ML, CAD, виртуальные машины', cpu: 'Ryzen 5 7600', gpu: 'RTX 4060', ram: '32 GB DDR5', storage: '1 TB SSD' },
            '1200_plus': { name: 'Учебный Max', price: '4200 BYN', description: 'Любые учебные проекты', cpu: 'Ryzen 7 7700X', gpu: 'RTX 4070', ram: '32 GB DDR5', storage: '1 TB NVMe' },
        },
        all: {
            up_to_500: { name: 'Универсал Start', price: '1550 BYN', description: 'Игры, работа и учёба', cpu: 'Ryzen 5 5500', gpu: 'GTX 1660 Super', ram: '16 GB DDR4', storage: '512 GB SSD' },
            '500_800': { name: 'Универсал Balance', price: '2450 BYN', description: 'Золотая середина', cpu: 'Ryzen 5 7600', gpu: 'RTX 4060', ram: '16 GB DDR5', storage: '1 TB SSD' },
            '800_1200': { name: 'Универсал Pro', price: '3700 BYN', description: 'Мощный ПК без узких мест', cpu: 'Ryzen 7 7700X', gpu: 'RTX 4070 Super', ram: '32 GB DDR5', storage: '1 TB NVMe' },
            '1200_plus': { name: 'Универсал Ultra', price: '5500 BYN', description: 'Топовый ПК на все случаи', cpu: 'Ryzen 7 7800X3D', gpu: 'RTX 4080 Super', ram: '32 GB DDR5', storage: '2 TB NVMe' },
        },
    };

    const state = { purpose: null, budget: null, step: 1, prefillBuild: quizSection.dataset.prefillBuild || '' };
    const steps = quizSection.querySelectorAll('.quiz-step');
    const progressBar = document.getElementById('progress-bar');
    const progressText = document.getElementById('progress-text');
    const progressPercent = document.getElementById('progress-percent');
    const quizError = document.getElementById('quiz-error');
    const submitUrl = quizSection.dataset.submitUrl;

    function getCookie(name) {
        const match = document.cookie.match(new RegExp('(^| )' + name + '=([^;]+)'));
        return match ? decodeURIComponent(match[2]) : null;
    }

    function showError(msg) {
        quizError.textContent = msg;
        quizError.style.display = 'block';
    }

    function hideError() {
        quizError.style.display = 'none';
    }

    function goToStep(step) {
        state.step = step;
        steps.forEach(function (el) {
            el.classList.toggle('active', el.dataset.step === String(step));
        });

        if (step === 'success') {
            progressBar.style.width = '100%';
            progressText.textContent = 'Готово';
            progressPercent.textContent = '100%';
            return;
        }

        const pct = Math.round((step / 3) * 100);
        progressBar.style.width = pct + '%';
        progressText.textContent = 'Шаг ' + step + ' из 3';
        progressPercent.textContent = pct + '%';
        hideError();

        if (step === 3) renderRecommendation();
    }

    function setupCards(containerId, field, nextBtnId) {
        const container = document.getElementById(containerId);
        const nextBtn = document.getElementById(nextBtnId);
        if (!container || !nextBtn) return;

        container.querySelectorAll('.quiz-card').forEach(function (card) {
            card.addEventListener('click', function () {
                container.querySelectorAll('.quiz-card').forEach(function (c) {
                    c.classList.remove('selected');
                });
                card.classList.add('selected');
                card.querySelector('input').checked = true;
                state[field] = card.dataset.value;
                nextBtn.disabled = false;
            });
        });
    }

    function renderRecommendation() {
        let build;
        if (state.prefillBuild) {
            build = { name: state.prefillBuild, price: '—', description: 'Выбранная сборка из каталога', cpu: '—', gpu: '—', ram: '—', storage: '—' };
        } else {
            build = RECOMMENDATIONS[state.purpose][state.budget];
        }
        document.getElementById('rec-name').textContent = build.name;
        document.getElementById('rec-price').textContent = build.price;
        document.getElementById('rec-desc').textContent = build.description;
        document.getElementById('rec-specs').innerHTML =
            '<span>CPU: ' + build.cpu + '</span>' +
            '<span>GPU: ' + build.gpu + '</span>' +
            '<span>RAM: ' + build.ram + '</span>' +
            '<span>SSD: ' + build.storage + '</span>';
    }

    function getRecommendedBuild() {
        if (state.prefillBuild) {
            return { name: state.prefillBuild };
        }
        return RECOMMENDATIONS[state.purpose][state.budget];
    }

    setupCards('purpose-cards', 'purpose', 'btn-next-1');
    setupCards('budget-cards', 'budget', 'btn-next-2');

    document.getElementById('btn-next-1').addEventListener('click', function () {
        if (state.purpose) goToStep(2);
    });
    document.getElementById('btn-back-2').addEventListener('click', function () { goToStep(1); });
    document.getElementById('btn-next-2').addEventListener('click', function () {
        if (state.budget) goToStep(3);
    });
    document.getElementById('btn-back-3').addEventListener('click', function () { goToStep(2); });

    document.getElementById('btn-submit').addEventListener('click', function () {
        hideError();
        const name = document.getElementById('quiz-name').value.trim();
        const contact = document.getElementById('quiz-contact').value.trim();
        const build = getRecommendedBuild();

        if (!name) { showError('Введите ваше имя'); return; }
        if (!contact) { showError('Укажите телефон или Telegram'); return; }

        const btn = document.getElementById('btn-submit');
        btn.disabled = true;
        btn.textContent = 'Отправка…';

        const payload = {
            name: name,
            contact: contact,
            budget: state.budget || '500_800',
            purpose: state.purpose || 'all',
            comment: build.name,
        };

        const buildId = quizSection.dataset.buildId;
        if (buildId) payload.build = buildId;

        fetch(submitUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRFToken': getCookie('csrftoken'),
                'X-Requested-With': 'XMLHttpRequest',
            },
            body: JSON.stringify(payload),
        })
        .then(function (res) {
            return res.json().then(function (data) { return { ok: res.ok, data: data }; });
        })
        .then(function (result) {
            if (result.ok && result.data.status === 'ok') {
                goToStep('success');
            } else {
                let msg = 'Ошибка отправки. Проверьте данные.';
                if (result.data.errors) {
                    msg = Object.values(result.data.errors).flat().join(' ');
                }
                showError(msg);
            }
        })
        .catch(function () {
            showError('Не удалось отправить заявку. Попробуйте ещё раз.');
        })
        .finally(function () {
            btn.disabled = false;
            btn.textContent = 'Получить подборку';
        });
    });

    document.getElementById('btn-restart').addEventListener('click', function () {
        state.purpose = null;
        state.budget = null;
        document.getElementById('quiz-name').value = '';
        document.getElementById('quiz-contact').value = '';
        quizSection.querySelectorAll('.quiz-card').forEach(function (c) {
            c.classList.remove('selected');
            c.querySelector('input').checked = false;
        });
        document.getElementById('btn-next-1').disabled = true;
        document.getElementById('btn-next-2').disabled = true;
        goToStep(1);
    });

    if (state.prefillBuild) {
        goToStep(3);
    }
})();
