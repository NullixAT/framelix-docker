FROM bitnami/php-fpm:8.1-prod

RUN install_packages cron && mkdir -p /etc/cron.app
COPY config/cronjobs /etc/cron.app/cronjobs
COPY config/php-fpm-entrypoint.sh /
COPY config/php.ini /opt/bitnami/php/etc/php.ini
RUN chmod -R 0755 /etc/cron.app
RUN chmod 0755 /php-fpm-entrypoint.sh
RUN crontab /etc/cron.app/cronjobs && touch /var/log/cron.log
ENTRYPOINT [ "/php-fpm-entrypoint.sh" ]
