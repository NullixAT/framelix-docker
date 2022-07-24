#!/bin/bash

USERNAME=$(id -n -u ${USER_ID})
GROUPNAME=$(id -n -u ${GROUP_ID})

echo Running with USER/USER_ID: $USERNAME/$USER_ID
echo Running with GROUP/GROUP_ID: $GROUPNAME/$GROUP_ID

NODEDIR="/usr/local/lib/nodejs"
if [ ! -d "$NODEDIR/bin" ]; then
  echo "===Downloading NodeJS==="
  wget -qO- https://nodejs.org/dist/v16.14.2/node-v16.14.2-linux-x64.tar | tar -xv --strip 1 -C $NODEDIR
  chown $USER_ID:$GROUP_ID -R $NODEDIR
  echo "===Done==="
  echo ""
fi

echo "===Creating NodeJS Symlinks==="
ln -s -f $NODEDIR/bin/node /usr/bin/node
ln -s -f $NODEDIR/bin/npm /usr/bin/npm
echo "===Done==="
echo ""

echo "===Starting cron==="
service cron start
echo "===Done==="
echo ""

echo "===Running Framelix Bootstrap==="
runuser -u $USERNAME -g $GROUPNAME /opt/bitnami/php/bin/php /framelix-scripts/php-fpm-entrypoint-bootstrap.php
status=$?

if test $status -eq 0; then
  echo "===Done==="
  echo ""

  echo "===Run NPM install in modules/*==="
  for d in /framelix/modules/*/ ; do
    if test -f "$d/package.json"; then
      echo "NPM install in $d..."
      cd $d
      npm install
      echo "OK"
      echo ""
    fi
  done
  echo "===Done==="
  echo ""

  echo "===Starting PHP-fpm ==="
  php-fpm -F --pid /opt/bitnami/php/tmp/php-fpm.pid -y /opt/bitnami/php/etc/php-fpm.conf

else
  echo "===Failed==="
fi
