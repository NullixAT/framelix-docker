#!/bin/bash

NODEDIR="/usr/local/lib/nodejs"
if [ ! -d "$NODEDIR/bin" ]; then
  echo "===Downloading NodeJS==="
  wget -qO- https://nodejs.org/dist/v16.14.2/node-v16.14.2-linux-x64.tar | tar -xv --strip 1 -C $NODEDIR
  echo "===Done==="
  echo ""
fi

echo "===Creating NodeJS Symlinks==="
ln -s $NODEDIR/bin/node /usr/bin/node
ln -s $NODEDIR/bin/npm /usr/bin/npm
echo "===Done==="
  echo ""

echo "===Starting cron==="
service cron start
echo "===Done==="
  echo ""

echo "===Running Framelix Bootstrap==="
/opt/bitnami/php/bin/php /framelix-scripts/php-fpm-entrypoint-bootstrap.php
status=$?

if test $status -eq 0; then
  echo "===Done==="
  echo ""

  echo "===Forcing all appfiles to run under daemon user==="
  chown -R daemon:daemon /framelix
  echo "===Done==="
  echo ""

  echo "===Run NPM install in modules/Framelix ==="
    cd /framelix/modules/Framelix
    npm install
  echo "===Done==="
  echo ""

  echo "===Starting PHP-fpm ==="
  php-fpm -F --pid /opt/bitnami/php/tmp/php-fpm.pid -y /opt/bitnami/php/etc/php-fpm.conf

else
  echo "===Failed==="
fi
