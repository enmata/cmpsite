# cmpapi/urls.py
from django.urls import include, path
from rest_framework import routers
from . import views

router = routers.DefaultRouter()
router.register(r'user', views.CMPUserViewSet)

# Wire up our API using automatic URL routing.
# Additionally, we include login URLs for the browsable API.
urlpatterns = [
    #HTTP/plain access
    path('', include(router.urls)),
    path('api-auth/', include('rest_framework.urls', namespace='rest_framework')),
    path('hc/', include('health_check.urls')),
    #HTTPS/TLS access
    path('secure/', include(router.urls)),
    path('secure/api-auth/', include('rest_framework.urls', namespace='rest_framework')),
    path('secure/hc/', include('health_check.urls')),
]
