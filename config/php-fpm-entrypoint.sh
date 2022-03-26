#!/bin/bash

# install or update nodejs if required
NODEDIR="/usr/local/lib/nodejs"
if [ ! -d "$NODEDIR/bin" ] ; then
  wget -qO- https://nodejs.org/dist/v16.14.2/node-v16.14.2-linux-x64.tar | tar -xv --strip 1 -C $NODEDIR
fi

# symlink node and npm
ln -s $NODEDIR/bin/node /usr/bin/node
ln -s $NODEDIR/bin/npm /usr/bin/npm

# start cron
service cron start

# run bootstrap script
/opt/bitnami/php/bin/php /framelix-scripts/php-fpm-entrypoint-bootstrap.php

# forcing all files to daemon user
chown -R daemon:daemon /framelix

# run npm install if not yet installed
if [ ! -d "/framelix/modules/Framelix/node_modules" ] ; then
  cd /framelix/modules/Framelix
  npm install
fi

# start fpm process
php-fpm -F --pid /opt/bitnami/php/tmp/php-fpm.pid -y /opt/bitnami/php/etc/php-fpm.conf

