from django.db import models


class Build(models.Model):
    CATEGORY_CHOICES = [
        ('gaming', 'Игровой'),
        ('work', 'Рабочий'),
        ('study', 'Учебный'),
        ('universal', 'Универсальный'),
    ]

    CPU_BRAND_CHOICES = [
        ('intel', 'Intel'),
        ('amd', 'AMD'),
    ]

    name = models.CharField('Название', max_length=200)
    slug = models.SlugField('URL-slug', unique=True)
    category = models.CharField('Категория', max_length=20, choices=CATEGORY_CHOICES)
    cpu_brand = models.CharField('Бренд CPU', max_length=10, choices=CPU_BRAND_CHOICES, default='amd')
    price = models.DecimalField('Цена (BYN)', max_digits=10, decimal_places=2)
    description = models.TextField('Описание')
    cpu = models.CharField('Процессор', max_length=200)
    gpu = models.CharField('Видеокарта', max_length=200)
    ram = models.CharField('Оперативная память', max_length=100)
    storage = models.CharField('Накопитель', max_length=100)
    case = models.CharField('Корпус', max_length=100)
    is_popular = models.BooleanField('Хит продаж', default=False)
    is_active = models.BooleanField('Активна', default=True)
    image = models.ImageField('Изображение', upload_to='builds/', blank=True)
    created_at = models.DateTimeField('Создано', auto_now_add=True)

    class Meta:
        verbose_name = 'Сборка'
        verbose_name_plural = 'Сборки'
        ordering = ['-created_at']

    def __str__(self):
        return self.name


class Order(models.Model):
    BUDGET_CHOICES = [
        ('up_to_500', 'До 500$'),
        ('500_800', '500–800$'),
        ('800_1200', '800–1200$'),
        ('1200_plus', '1200$+'),
    ]

    PURPOSE_CHOICES = [
        ('games', 'Игры'),
        ('work', 'Работа'),
        ('study', 'Учёба'),
        ('all', 'Всё сразу'),
    ]

    name = models.CharField('Имя', max_length=100)
    contact = models.CharField('Контакт', max_length=100)
    budget = models.CharField('Бюджет', max_length=20, choices=BUDGET_CHOICES)
    purpose = models.CharField('Цель', max_length=20, choices=PURPOSE_CHOICES)
    build = models.ForeignKey(
        Build,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        verbose_name='Выбранная сборка',
    )
    comment = models.TextField('Комментарий', blank=True)
    is_processed = models.BooleanField('Обработана', default=False)
    created_at = models.DateTimeField('Создана', auto_now_add=True)

    class Meta:
        verbose_name = 'Заявка'
        verbose_name_plural = 'Заявки'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.name} — {self.get_budget_display()}'


class Review(models.Model):
    RATING_CHOICES = [(i, str(i)) for i in range(1, 6)]

    author = models.CharField('Автор', max_length=100)
    text = models.TextField('Текст')
    rating = models.IntegerField('Оценка', choices=RATING_CHOICES)
    created_at = models.DateTimeField('Создан', auto_now_add=True)
    is_published = models.BooleanField('Опубликован', default=False)

    class Meta:
        verbose_name = 'Отзыв'
        verbose_name_plural = 'Отзывы'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.author} — {self.rating}★'


class GalleryPhoto(models.Model):
    image = models.ImageField('Фото', upload_to='gallery/')
    caption = models.CharField('Подпись', max_length=200, blank=True)
    order = models.IntegerField('Порядок', default=0)

    class Meta:
        verbose_name = 'Фото галереи'
        verbose_name_plural = 'Фото галереи'
        ordering = ['order']

    def __str__(self):
        return self.caption or f'Фото #{self.pk}'
