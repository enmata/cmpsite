# cmpapi/views.py
from rest_framework import viewsets

from .serializers import CMPUserSerializer
from .models import CMPUser
import logging
import os

# Creating the logger
logger = logging.getLogger(__file__)

class CMPUserViewSet(viewsets.ModelViewSet):
    queryset = CMPUser.objects.all().order_by('name')
    serializer_class = CMPUserSerializer
    # Allowing only needed methods
    http_method_names = ['get', 'post', 'delete']
