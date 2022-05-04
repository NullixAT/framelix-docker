# Docker Setup for [Apps built with Framelix Php Framework](https://github.com/NullixAT/framelix-core)

Any framelix based app can be set up in this docker implementation.

## Setup

You need `docker` and `docker-compose` installed. This exists for almost every OS, even Windows and Mac. `git` is
required if you want to clone from this repository.
More [how Docker itself works here](https://docs.docker.com/get-docker/).

### Production Setup

```shell
mkdir myappinstance
cd myappinstance
wget {GITHUB_HTTPS_REPO_URL}/releases/latest/download/docker-release.tar -O docker-release.tar
tar xf docker-release.tar
rm docker-release.tar
cp config/env-default .env
docker-compose build
docker-compose up -d
```

Open `https://yourdomainorip:8686` and follow instructions in your browser. The container is configured to restart
always, also after host reboot.

### Development Setup

    git clone https://github.com/NullixAT/framelix-docker.git
    cd framelix-docker
    cp config/env-default .env
    git clone --recurse-submodules --branch main YOUR_APP_REPOSITORY_URL app
    docker-compose build
    docker-compose up -d

Open `https://yourdomainorip:8686` and follow instructions in your browser. The container is configured to restart
always, also after host reboot.

## Configuring port and http/https config

By default, port 8686 is used and uses https.

There are 2 ports available inside the service:

* `80` for http handling. Example: `WEBPORT_MAP=8686:80`
* `443` for https handling. Example: `WEBPORT_MAP=8686:443`

You can swap `8686` to any port you like. It's the port from which your page is available.

SSL is default enabled with self-signed certificates. You may get browser warnings when you open the page (which you can
bypass in case of localhost or in incognito mode).

You can pass your own certificates. If you have no other webservice running on your host, you can
modify `NGINX_SSL_CERT` and `NGINX_SSL_KEY`. If you not already have certificates, we recommend to
use [Certbot](https://certbot.eff.org/).

However, recommended way is to have a separate webserver running on the host, which acts as a reverse proxy, which
handles certificates and other stuff. See config example for Nginx down bellow. With this way, you can setup multiple
docker installations on one host and even have other services on the public port.

> If you change https/http and the app is already installed, you must modify `app/modules/xxx/config-editable.php` as
> well.

## Folder structure

All application source files and uploaded files in the application are in the folder `app`.

All database files are in the folder `db`.

## Backup Database

You can either backup the whole `db` folder or you can do a proper sql dump with:

`docker-compose exec db mysqldump app -u app -papp > backup.sql` which stores a backup to `backup.sql`

## Restore database

Restore from a dump sql file:

`docker-compose exec db mysql app -u app -papp app < backup.sql`

Or, if you have a backup of the whole `db` folder:

1. shutdown the service `docker-compose down`
2. Delete everything in `db`
3. Copy your backup files back into `db`
4. Start the service `docker-compose up -d`

## Install/Restore from a full app backup

Follow this steps if you have made an app backup downloaded from the backend and you want to revert to the state of the
backup.

> Warning: This step requires to delete all existing data and to shut down the docker service.

The downloaded `backup.zip` must contain 2 folders: `appfiles` and `appdatabase`.

1. Shutdown the service with `docker-compose down`
2. Attention: Delete everything inside `app` and delete everything inside `db`
3. Copy the `backup.zip` into `app/backup.zip`
4. Start the container with `docker-compose up -d`
5. (Optional) Maybe you've moved from another installation, db or whatever to this docker container, you probably need
   to modify `modules/xxx/config-editable.php` db and other settings to your needs to make it fully functional

### Example Nginx Proxy Config

This is what we use to run the docker service through a nginx proxy.

    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        root /path-to-app-docker-root/app;
        server_name yourdomain.com;
        ssl_certificate     /pathtosslcert.pem;
        ssl_certificate_key /pathtosslkey.pem;    
        client_max_body_size 1000M;
        location / {
            proxy_pass http://127.0.0.1:7001;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header X-Forwarded-Proto https;
            proxy_ssl_server_name on;
        }
    }}

