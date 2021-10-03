#!/bin/bash

#Testing though django framework if the application passes all the documented Deployment checks
#https://docs.djangoproject.com/en/3.0/howto/deployment/checklist/

echo "--Creating virtual environment--"
cd testing
virtualenv -q testing_venv
source testing_venv/bin/activate

echo "--Installing dependencies--"
pip install -q -r requirements_testing_wrapper_local.txt

echo "--Emulating Container execution environment--"
export DJANGO_SECRET_KEY='&rvth@q684+xehh!myc!h%6hz#cs)94iobgkbmdnu7vj@*y3&+'
export DJANGO_DEBUG="True"
export DJANGO_ALLOWED_HOSTS="192.168.99.107"
export DJANGO_BASE_URL="http://192.168.99.107:30008"
export DJANGO_SUPERUSER_EMAIL=admin@cmpsite.com
export DJANGO_SUPERUSER_USERNAME=admin
export DJANGO_SUPERUSER_PASSWORD=Barcelona.1

echo "--Initalizing application--"
cd ../docker/cmpsite
python3 manage.py makemigrations
python3 manage.py migrate
python3 manage.py flush --noinput
python3 manage.py createsuperuser --email $DJANGO_SUPERUSER_EMAIL --username $DJANGO_SUPERUSER_USERNAME --noinput

echo "--Running tests--"
python3 manage.py check --deploy --verbosity 3

echo "--Cleaning up--"
rm cmpsite/cmpdb/db.sqlite3
rm -rf ../../testing/testing_venv
deactivate
cd ..
