# Docker Setup for [Apps built with Framelix Php Framework](https://github.com/NullixAT/framelix-docs)

Almost any framelix based app can be set up in this docker implementation.

## Setup

You need `docker` and `docker-compose` installed. This exists for almost every OS, even Windows and Mac. `git` is
required if you want to clone from this repository.
More [how Docker itself works here](https://docs.docker.com/get-docker/).

First, clone (or download a zip of) this repository and generate default configs:

    git clone https://github.com/NullixAT/framelix-docker.git
    cd framelix-docker
    cp config/env-default .env
    cp config/nginx-config-template.conf nginx-config.conf

#### Modify .env

`FRAMELIX_MODULE` should be your module name, which in this demo is `Demo`.

`INITIAL_GITHUB_RELEASE_URL` can be set to a github api url where the script automatically should download the release
file from. In this demo you need to set it to `https://api.github.com/repos/NullixAT/framelix-docs/releases/latest`.

If you have a specific `release.zip` already downloaded, place it into the `app` folder, it will be installed instead of
using the value from `INITIAL_GITHUB_RELEASE_URL`.

#### Port http/https config

There are 2 ports available inside the service:

* `80` for http handling. Example: `WEBPORT_MAP=8080:80`
* `443` for https handling. Example: `WEBPORT_MAP=8080:443`

You can swap `8080` to any port you like. It's the port from which your page is available.

SSL is default enabled with self signed certificates. You may get browser warnings when you open the page (which you can
bypass in case of localhost or in incognito mode).

You can pass your own certificates. If you have no other webservice running on your host, you can
modify `NGINX_SSL_CERT` and `NGINX_SSL_KEY`. If you not already have certificates, we recommend to
use [Certbot](https://certbot.eff.org/).

However, recommended way is to have a separate webserver running on the host, which acts as a reverse proxy, which
handles certificates and other stuff. See config example for Nginx down bellow. With this way, you can setup multiple
docker installations of PageMyself on one host and even have other services on the public port.

> If you change https/http and the app is already installed, you must modify `app/modules/Demo/config-editable.php` as well.

## Build and Run

After changing something in the configs or on initial setup, run:

    docker-compose build

Star the docker service with:

    docker-compose up -d

Open `https://yourdomainorip:8080` and follow instructions in your browser. The container is configured to restart
always, also after host reboot.

All application source files and uploaded files in the application are in the folder `app`.

All database files are in the folder `db`.

## Install/Restore from an app backup

Follow this steps if you have made an app backup downloaded from the backend and you want to revert to the state of the
backup.

> Warning: This step requires to delete all existing data and to shut down the docker service.

The downloaded `backup.zip` contains 2 folders: `appdatabase` and `appdatabase`.

1. Shutdown the service with `docker-compose down`
2. Attention: Delete everything in `app` and delete everything in `db`
3. Copy the `backup.zip` into `app/backup.zip`
4. Start the container with `docker-compose up`
5. (Optional) Maybe you've moved from another installation, db or whatever to this docker container, you probably need
   to modify `modules/Myself/config-editable.php` db and other settings to your needs to make it fully functional

### Example Nginx Config

This is what we use to run the docker service through a nginx proxy.

    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        root /path-to-app-docker-root/app;
        server_name yourdomain.com;
        ssl_certificate     /pathtosslcert.pem;
        ssl_certificate_key /pathtosslkey.pem;    
        client_max_body_size 100M;
        location / {
            proxy_pass http://127.0.0.1:7001;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header X-Forwarded-Proto https;
            proxy_ssl_server_name on;
        }
    }}

