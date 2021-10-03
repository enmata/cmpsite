# cmpapi/models.py
from django.db import models

class CMPUser(models.Model):
    name = models.CharField(max_length=50)
    def __str__(self):
        return self.name
