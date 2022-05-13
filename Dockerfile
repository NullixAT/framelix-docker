FROM bitnami/php-fpm:8.1-prod

ARG USER_ID
ARG GROUP_ID

RUN install_packages cron && mkdir -p /etc/cron.app
COPY config/cronjobs /etc/cron.app/cronjobs
COPY config/php-fpm-entrypoint.sh /
COPY config/php.ini /opt/bitnami/php/etc/php.ini
RUN chmod -R 0755 /etc/cron.app
RUN chmod 0755 /php-fpm-entrypoint.sh
RUN crontab /etc/cron.app/cronjobs && touch /var/log/cron.log

# create missing group that have been passed from the host
RUN if ! getent group ${GROUP_ID} >/dev/null ; then \
    groupadd -g ${GROUP_ID} framelix\
;fi

# create missing user that have been passed from the host
RUN if ! getent passwd ${USER_ID} >/dev/null  ; then \
    useradd -l -u ${USER_ID} -g ${GROUP_ID} framelix\
;fi

RUN USERNAME=$(id -n -u ${USER_ID}) && GROUPNAME=$(id -n -u ${GROUP_ID}) && usermod -a -G $GROUPNAME $USERNAME

# create custom conf representing the actual uid and gid
# because we can't use this this env variables directly in the config
RUN echo [www] > /opt/bitnami/php/etc/php-fpm.d/www-user.conf && \
    echo "user = ${USER_ID}" >> /opt/bitnami/php/etc/php-fpm.d/www-user.conf && \
    echo "group = ${GROUP_ID}" >> /opt/bitnami/php/etc/php-fpm.d/www-user.conf

ENTRYPOINT [ "/php-fpm-entrypoint.sh" ]
