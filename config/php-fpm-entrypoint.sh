#!/bin/bash

service cron start
/opt/bitnami/php/bin/php /framelix-scripts/php-fpm-entrypoint-bootstrap.php
chown -R daemon:daemon /framelix
php-fpm -F --pid /opt/bitnami/php/tmp/php-fpm.pid -y /opt/bitnami/php/etc/php-fpm.conf

