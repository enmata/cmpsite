python3 manage.py makemigrations
python3 manage.py migrate
python3 manage.py flush --noinput
# Parameters DJANGO_SUPERUSER_USERNAME, DJANGO_SUPERUSER_PASSWORD DJANGO_SUPERUSER_EMAIL parameters will be read from secret "cmpdb-secret"
python3 manage.py createsuperuser --username $DJANGO_SUPERUSER_USERNAME --email $DJANGO_SUPERUSER_EMAIL --noinput
