# cmpapi/serializers.py
from rest_framework import serializers

from .models import CMPUser

class CMPUserSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = CMPUser
        fields = ('id', 'name')
