#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "===Docker Instance Update==="
echo "This script will download the current docker-update.zip corresponding to the latest app version you have installed"
echo "WARNING: This will override existing docker config and maybe update some containers (Nginx, Php, Mysql updates)"
echo "It is recommended to have a backup before updating"
echo ""
echo "The update will do the following:"
echo "1. Shutdown the instance with docker-compose down"
echo "2. Copy update files"
echo "3. Rebuild the container to applying updates with docker-compose build"
echo "4. Restart the service"
echo ""

echo -n "Do you want to proceed (y/n): "
read answer
if [[ ! $answer =~ ^[Yy]$ ]]; then
  exit 1
fi
echo ""

docker-compose exec phpfpm php /framelix/modules/Framelix/console.php prepareDockerUpdate
status=$?

echo ""
if test $status -ne 0; then
  echo "Error while fetching docker-update.zip"
  exit 1
fi

echo "Docker update downloaded successfully"
echo ""

echo "Shutting down service now"
echo ""
docker-compose down
echo ""
echo ""

echo "Copy update files"
echo ""
cp -Rvf $SCRIPT_DIR/app/modules/Framelix/tmp/docker-update/* $SCRIPT_DIR
rm -Rf $SCRIPT_DIR/app/modules/Framelix/tmp/docker-update
echo ""
echo ""

echo "Rebuild the container to applying updates with docker-compose build"
echo ""
docker-compose build
echo ""
echo ""

echo "Restarting container"
echo ""
docker-compose up -d
echo ""
echo ""

echo "Done"
