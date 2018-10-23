from django.conf.urls import url
from monhan import views

urlpatterns = [
    # 防具
    url(r'^$', views.index, name='index'),
    url(r'^armor/$', views.armor_list, name='armor_list'),
    url(r'^skill/$', views.skill_list, name='skill_list'),
    url(r'^item/$', views.item_list, name='item_list'),
    url(r'^search_armors$', views.search_armors, name='search_armors'),
    url(r'^coodinate_armor_set$', views.coodinate_armor_set, name='coodinate_armor_set'),
]
