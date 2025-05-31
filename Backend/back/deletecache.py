
#!delete cache



#! python manage.py shell

from django.core.cache import cache

cache.clear()





#! delete recent actions



#!python manage.py shell

from django.contrib.admin.models import LogEntry
LogEntry.objects.all().delete()
