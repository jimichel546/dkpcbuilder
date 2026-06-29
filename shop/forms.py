from django import forms

from .models import Order


class OrderForm(forms.ModelForm):
    class Meta:
        model = Order
        fields = ['name', 'contact', 'budget', 'purpose', 'build', 'comment']
        widgets = {
            'build': forms.HiddenInput(),
            'comment': forms.Textarea(attrs={'rows': 4}),
        }


class ContactForm(forms.ModelForm):
    class Meta:
        model = Order
        fields = ['name', 'contact', 'comment']
        labels = {
            'name': 'Ваше имя',
            'contact': 'Телефон или Telegram',
            'comment': 'Расскажите о проекте',
        }
        widgets = {
            'name': forms.TextInput(attrs={'placeholder': 'Как к вам обращаться'}),
            'contact': forms.TextInput(attrs={'placeholder': '+375... или @username'}),
            'comment': forms.Textarea(attrs={
                'rows': 5,
                'placeholder': 'Задачи, пожелания по сборке, бюджет — всё, что считаете важным',
            }),
        }

    def save(self, commit=True):
        order = super().save(commit=False)
        order.budget = '500_800'
        order.purpose = 'all'
        prefix = 'Форма «Ваш проект. Наше исполнение.»'
        order.comment = f'{prefix}\n{order.comment}' if order.comment else prefix
        if commit:
            order.save()
        return order
