#!/usr/bin/env bash
docker_start_main_services() {
#    php artisan migrate --force
#    php artisan config:clear
#    service cron restart
#    nohup php artisan queue:work --daemon &
    /usr/bin/supervisord -n -c /etc/supervisord.conf &
    apache2-foreground
}

_main() {
    docker_start_main_services
}

_main
