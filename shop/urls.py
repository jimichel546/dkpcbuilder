from django.urls import path

from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('catalog/', views.catalog, name='catalog'),
    path('catalog/<slug:slug>/', views.build_detail, name='build_detail'),
    path('order/', views.submit_order, name='submit_order'),
    path('success/', views.quiz_success, name='quiz_success'),
    path('privacy/', views.static_page, {'page': 'privacy'}, name='privacy'),
    path('terms/', views.static_page, {'page': 'terms'}, name='terms'),
    path('cookies/', views.static_page, {'page': 'cookies'}, name='cookies'),
]
