#!/bin/bash

echo "===First time setup==="

if [  -d "app" ] ; then
  echo "Your /app folder already exists - Setup already done. Bye."
  exit 0
fi

if [  -d "app" ] ; then
  echo "Your /app folder already exists - Setup already done. Bye."
  exit 0
fi

if [  -d "db/app" ] ; then
  echo "Your database already contains appdata - Setup not possible. Bye."
  exit 0
fi

echo -n "URL to a docker-release.zip: "
read url