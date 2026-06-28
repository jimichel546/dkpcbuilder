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
