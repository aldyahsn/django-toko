#!/bin/bash

# Generate passowrds
DBPASS=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12`
GREEN='\033[1;36m'
WHITE='\033[1;37m'
# ==============================================================
printf "===================================\n"
printf "🔆🔆🔆  SETUP DJANGO PROJECT 🔆🔆🔆\n"
printf "===================================\n"
# ==============================================================
printf "===================================\n"
echo -ne "Enter your domain name:\n"
printf "===================================\n"
read DOMAIN

printf "===================================\n"
printf "\n\nChoose Action:\n1) Setup Server\n2) Delete Website (You can't undo)\n"
printf "===================================\n"
read ACTION

if [ -z "$ACTION" ] 
then
    printf "===================================\n"
	printf "NO ACTION SELECTED 🤷‍♂️\n"
    printf "===================================\n"



elif [ $ACTION -eq 1 ]
then
HOMEDIR="/home/${USER}/websites/${DOMAIN}"
mkdir -p "$HOMEDIR/.venv"
mkdir -p "$HOMEDIR/public/static"
mkdir -p "$HOMEDIR/public/upload"
mkdir -p "$HOMEDIR/assets"
mkdir -p "$HOMEDIR/templates"

cd $HOMEDIR

# ==============================================================

sudo -H pip install -U pipenv

pipenv install django gunicorn django-environ psycopg2 pillow whitenoise djlint
source "$HOMEDIR/.venv/bin/activate"
django-admin startproject config
mv $HOMEDIR/config $HOMEDIR/src

# ==============================================================
printf "\n${GREEN}✅ Django Installed ${WHITE}"
# ==============================================================


touch $HOMEDIR/.env
echo "
#-- KEY
SECRET_KEY=$DBPASS

#-- DEBUG STATUS
DEBUG=True

#-- HOST
HOSTS=127.0.0.1,0.0.0.0,localhost,$DOMAIN,www.$DOMAIN

#-- POSTGRESQL CONFIG
#DATABASE_URL=psql://yourusername:yourpassword@127.0.0.1:5432/yourdatabase

#-- SQLITE CONFIG
DATABASE_URL=sqlite:///sqlite.db

#-- MEMCACHE CONFIG
# CACHE_URL=memcache://127.0.0.1:11211,127.0.0.1:11212,127.0.0.1:11213

#-- REDIS CONFIG
# REDIS_URL=rediscache://127.0.0.1:6379/1?client_class=django_redis.client.DefaultClient&password=ungithubbed-secret
" | tee $HOMEDIR/.env >> $HOMEDIR/deploy.log


# ==============================================================
printf "\n${GREEN}✅ .env file created ${WHITE}"
# ==============================================================

echo "
from pathlib import Path
import environ
import os

BASE_DIR = Path(__file__).resolve().parent.parent

env = environ.Env()
environ.Env.read_env(os.path.join(BASE_DIR.parent, '.env'))

SECRET_KEY = env('SECRET_KEY')
DEBUG = env.bool('DEBUG')
ALLOWED_HOSTS = env.list('HOSTS')

INSTALLED_APPS = [

    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]


MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',

    'whitenoise.middleware.WhiteNoiseMiddleware',
]

ROOT_URLCONF = 'config.urls'
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [
            BASE_DIR.parent / 'templates'
        ],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'
DATABASES = {
    'default':env.db()
}

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True


STATIC_URL = '/static/'
STATICFILES_DIRS = [BASE_DIR.parent / 'assets', ]
STATIC_ROOT = BASE_DIR.parent / 'public/static'
#STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage' # Compress + Caching
STATICFILES_STORAGE = 'whitenoise.storage.CompressedStaticFilesStorage' # Compress Only

MEDIA_URL = '/upload/'
MEDIA_ROOT = BASE_DIR.parent / 'public/upload'


DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

" | tee $HOMEDIR/src/config/settings.py >> deploy.log

echo "
from django.contrib import admin
from django.urls import path
from django.conf import settings
from django.conf.urls.static import static
from django.views.generic import TemplateView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', TemplateView.as_view(template_name="maintenance.html")),
]

# Use a web server of your choice to serve the uploaded files. 
if settings.DEBUG == True:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

" | tee $HOMEDIR/src/config/urls.py >> deploy.log


# ==============================================================
printf "\n${GREEN}✅ Settings.py is configured ${WHITE}\n"
# ==============================================================


echo "

<!doctype html>
<title>Site Maintenance</title>
<style>
  body { text-align: center; padding: 150px; }
  h1 { font-size: 50px; }
  body { font: 20px Helvetica, sans-serif; color: #333; }
  article { display: block; text-align: left; width: 650px; margin: 0 auto; }
  a { color: #dc8100; text-decoration: none; }
  a:hover { color: #333; text-decoration: none; }
</style>

<article>
    <h1>We&rsquo;ll be back soon!</h1>
    <div>
        <p>Sorry for the inconvenience but we&rsquo;re performing some maintenance at the moment. 
        <p>&mdash; The Team</p>
    </div>
</article>
" | tee $HOMEDIR/templates/maintenance.html >> deploy.log

# ==============================================================
printf "\nTemplate Created\n"
# ==============================================================

echo "[Unit]
Description=gunicorn socket -> $DOMAIN

[Socket]
ListenStream=/run/gunicorn_$DOMAIN.sock

[Install]
WantedBy=sockets.target
"| sudo tee /etc/systemd/system/gunicorn_$DOMAIN.socket >> $HOMEDIR/deploy.log

# ==============================================================

echo "[Unit]
Description=gunicorn $DOMAIN daemon
Requires=gunicorn_$DOMAIN.socket
After=network.target

[Service]
User=$USER
Group=www-data
WorkingDirectory=$HOMEDIR
ExecStart=$HOMEDIR/.venv/bin/gunicorn \
          --access-logfile - \
          --workers 3 \
          --bind unix:/run/gunicorn_$DOMAIN.sock \
	  --chdir $HOMEDIR/src \
          config.wsgi:application

[Install]
WantedBy=multi-user.target
" | sudo tee /etc/systemd/system/gunicorn_$DOMAIN.service >> $HOMEDIR/deploy.log

sudo systemctl start gunicorn_$DOMAIN.socket
sudo systemctl enable gunicorn_$DOMAIN.socket
curl --unix-socket /run/gunicorn_$DOMAIN.sock localhost >> $HOMEDIR/deploy.log
sudo systemctl daemon-reload

# ==============================================================
printf "\n${GREEN}✅ systemd is done ${WHITE}\n"
# ==============================================================

echo "server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    error_log /var/log/nginx/.$DOMAIN.error.log;
    access_log /var/log/nginx/.$DOMAIN.access.log;
    rewrite_log on;
    server_tokens off;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection '1; mode=block';

    location /static/ {
        root $HOMEDIR/public/static;
            expires 30d;
        log_not_found off;
        access_log off;
    }
    location /upload/ {
        root $HOMEDIR/public/upload;
            expires 30d;
        log_not_found off;
        access_log off;
     }
    location / {
        include proxy_params;
        proxy_pass http://unix:/run/gunicorn_$DOMAIN.sock;
    }
}
" | sudo tee /etc/nginx/sites-available/$DOMAIN >> $HOMEDIR/deploy.log
sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled
sudo systemctl restart nginx


# ==============================================================
printf "===================================\n"
printf "✅✅✅✅✅  ${GREEN}INSTALLATION COMPLETE  ✅✅✅✅✅\n"
printf "===================================\n"

elif [ $ACTION -eq 2 ]
then 

#!/bin/bash

sudo rm -r /home/$USER/websites/$DOMAIN
sudo systemctl stop gunicorn_$DOMAIN.service
sudo systemctl disable gunicorn_$DOMAIN.service

sudo systemctl stop gunicorn_$DOMAIN.socket
sudo systemctl disable gunicorn_$DOMAIN.socket

sudo rm /etc/systemd/system/gunicorn_$DOMAIN.service
sudo rm /etc/systemd/system/gunicorn_$DOMAIN.socket

sudo systemctl daemon-reload
sudo systemctl reset-failed

sudo rm /etc/nginx/sites-available/$DOMAIN
sudo rm /etc/nginx/sites-enabled/$DOMAIN

printf "===================================\n"
printf "😭 YOU DELETED WEBSITE 😭\n"
printf "===================================\n"
fi



