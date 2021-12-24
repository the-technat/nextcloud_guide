# 2 - Cloud Installation Guide (secure)

This guide shows how to install a Nextcloud Instance on a single cloud server with security-by-design.

## Preparations

The whole cloud fits one cloud server ;).

This tutorial uses a cloud server from Hetzner (CX21) using Debian Bullseye. Because linux OS configs for every server are cumbersome cloud-init comes to rescue. The following config was used:

```
#cloud-config for nc.technat.ch
fqdn: nc.technat.ch
hostname: nc
locale: en_US.UTF-8
timezone: Europe/Helsinki
package_upgrade: true
package_reboot_if_required: true
packages:
- vim
- bash-completion
- ufw
- unzip
- git
users:
- name: technat
  groups: sudo, www-data
  shell: /bin/bash
  sudo: ALL=(ALL) NOPASSWD:ALL
  passwd: $p93ysZiN9I6IANoR$15N0g0szEyM8/jfgiDImCdIy4EZCEPyhLpWrmOEk3CFYlCCe89y/sQHzHhS7YOFHaj8iXaMAS11oNAxYbVov5/
  ssh-authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDxHiApIRh83tFluFhdZK8XQxBqrPLprauWthB1diBNERL3oOjr2DAyiSmrxmKfXLH0Q+0JlrwIT1mDsyabW71Xl4QSMyyyvsPLLgndOOoQPRq4m7rmX3iamfalp/f9yRpKeOPFq7YwHf4nBOs1XAEb/KRFxQO+R4OFbuKCdtGCXwHc2ja4YN0b1kSeqo6tL5W5qN3FzFyzcLQXEbuUMKoXeyyb+rfwrC0+JcZSRMYGxNPswLDz/HwBcb2erYNr9XYjTRx44H6MJXHjmtv+Pa/5dRXcQEzvJQnZttAcosnFvLXzeY2VbKyQ9dcapoxh86mKzzWNEop4VPHOb6tk73oFqRGwDfGO6snp7GVBuLc021YPydyQh3Qk8n3LEy3hAq6MyeUu5U6yHwDxS14O4P/zwc09P1zwFwwFpT1zEa9G+3R4hrT11hk3/H2uLc58hKmKYxHToS0H1hBoCP4BHBcCBsmfaOmXB6XPb7QniGiQg3/c+oELgIGprGLE5TpZWYLO1eIhtiRJ/HmLNjLUMQTM+a/h6O0Y9TiwWBGPW/zD9B2XsDSkJFi7cMkCr2/2Bp4yoMmg2jFqdmlXNMl1l3EFxw5/G1wOHkLAa7easjwdgeEXw29UEUc6r6D0MtZyH1WJyVIwsB0cacV/72bJfcqqMlWgtfuLeYIeqS/HhtWnXQ== technat@xyz
write_files:
- path: /etc/ssh/sshd_config
  content: |
    Port 58222
    PermitRootLogin no
    PermitEmptyPasswords no
    PasswordAuthentication no
    PubkeyAuthentication yes
    Include /etc/ssh/sshd_config.d/*.conf  
    ChallengeResponseAuthentication no
    UsePAM yes
    # Allow client to pass locale environment variables
    AcceptEnv LANG LC_*
    X11Forwarding no
    PrintMotd no
    Subsystem    sftp    /usr/lib/openssh/sftp-server
runcmd:
  - systemctl restart sshd
  # Configure Firewall
  - ufw default deny incoming
  - ufw default allow outgoing
  - ufw allow 80/tcp
  - ufw allow 443/tcp
  - ufw allow 58222/tcp
  - ufw enable
```

Most cloud-providers support cloud-init configs so that it should be simple to copy, adjust and paste the above config to specific needs. If not, it's highly recommended to configure the same things manually once the server is up and running as this gives you some good defaults. Also change the passwords for root and the admin user.

If we got a server we know the IPv4/6 of it. As the cloud-init config says this tutorial configures a Nextcloud Instance for domain `nc.technat.ch` so the next step is to set the following DNS records:

* `nc.technat.ch IN A to 65.108.56.153`
* `nc.technat.ch IN AAAA to 2a01:4f9:c011:280c::1`
* `nc.technat.ch. IN CAA 0 issue "letsencrypt.org"`
* `nc.technat.ch. IN CAA 0 issuewild ";"`

Of course one could omit the AAAA record, but configuring a site on IPv6 is as easy as configuring a site on IPv4 so let's run dual-stack!

To continue establish an ssh session to the server.

### External OS Disk

Nextcloud is an application working with data. Therefore it makes sense to have a place to store data. Best practice is to keep this location outside of the local webroot. In a cloud-environment a good solution is to order a block-storage volume and attach this one to your server. After you have ordered and attached it to your server, you should be able to see it using \`lsblk\`:

```
NAME    MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda       8:0    0 343.3G  0 disk
├─sda1    8:1    0 343.2G  0 part /
├─sda14   8:14   0     1M  0 part
└─sda15   8:15   0   122M  0 part /boot/efi
sdb       8:16   0   500G  0 disk
sr0      11:0    1  1024M  0 rom
```

As you can see `/dev/sda` is already partitioned and mounted at `/`. This is our OS disk and we shouldn´t touch it. But `/dev/sdb`is empty and usable. So let's partition, format and mount the disk at `/nc-data`.

Start with partitioning:

```
technat@nc:~$ sudo fdisk /dev/sdb

Welcome to fdisk (util-linux 2.36.1).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Device does not contain a recognized partition table.
Created a new DOS disklabel with disk identifier 0xba2a5442.

Command (m for help): g
Created a new GPT disklabel (GUID: C402FF47-646B-EA47-B5E1-1B9A1728B54C).

Command (m for help): n
Partition number (1-128, default 1):
First sector (2048-1048575966, default 2048):
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-1048575966, default 1048575966):

Created a new partition 1 of type 'Linux filesystem' and of size 500 GiB.

Command (m for help): p
Disk /dev/sdb: 500 GiB, 536870912000 bytes, 1048576000 sectors
Disk model: Volume
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: C402FF47-646B-EA47-B5E1-1B9A1728B54C

Device     Start        End    Sectors  Size Type
/dev/sdb1   2048 1048575966 1048573919  500G Linux filesystem

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```

If you look at the output of `lsblk`now you should see one partition on our disk:

```
NAME    MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sdb       8:16   0   500G  0 disk
└─sdb1    8:17   0   500G  0 part
```

Next we give the disk a file-system. For linux if you have no special needs or knowledge use `ext4`:

```
technat@nc:~$ sudo mkfs.ext4 /dev/sdb1
mke2fs 1.46.2 (28-Feb-2021)
Discarding device blocks: done
Creating filesystem with 131071739 4k blocks and 32768000 inodes
Filesystem UUID: 7253167c-6d2a-4641-862a-9d1c4c2630a5
Superblock backups stored on blocks:
	32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
	4096000, 7962624, 11239424, 20480000, 23887872, 71663616, 78675968,
	102400000

Allocating group tables: done
Writing inode tables: done
Creating journal (262144 blocks): done
Writing superblocks and filesystem accounting information: done
```

With a file-system in place we can mount the disk:

```
technat@nc:~$ echo '/dev/sdb1   /nc-data    ext4  defaults 0 1' | sudo tee -a /etc/fstab
/dev/sdb1   /nc-data    ext4  defaults 0 1
technat@nc:~$ sudo mkdir /nc-data
```

This configures a mount-point in the `/etc/fstab`file. If you reboot the server the disk will be mounted automatically. Let's try that now: `sudo reboot`.

Now the disk is mounted:

```
technat@nc:~$ df -h
Filesystem      Size  Used Avail Use% Mounted on
udev             16G     0   16G   0% /dev
tmpfs           3.1G  656K  3.1G   1% /run
/dev/sda1       344G  6.7G  323G   3% /
tmpfs            16G     0   16G   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
/dev/sda15      121M  138K  120M   1% /boot/efi
/dev/sdb1       492G   28K  467G   1% /nc-data
tmpfs           3.1G     0  3.1G   0% /run/user/1000
```

## MariaDB

Preparations are done, your server is ready to be used. The first service we configure is MariaDB. Nextcloud supports several database backends, the most trivial one that is fairly easy to setup and reliable is MariaDB.

We get the official package (which brings a systemd service file to control it):

```
sudo apt install mariadb-server -y
# Control the service:
sudo systemctl status mariadb
sudo systemctl stop mariadb
sudo systemctl start mariabd
sudo systemctl restart mariadb
```

As you can see it's running. Before we setup a database for nextcloud. Let's configure some recommended things using a script that comes with it:

```
sudo mysql_secure_installation
```

* press ENTER to omit the question for the current root password
* Type Y to switch to Unix authentication
* Type n to not change the root password
* Type Y to remove the anonymous users
* Type Y to disallow remote root login
* Type Y to remove the test database and access lists
* Type Y to reload the privileges table now

This gives as a good base to start with. Now we can do some testing to see it is working properly:

```
sudo systemctl status mariadb
sudo mysqladmin version
sudo mysql -u root # Open MariaDB prompt using root
exit
```

### Nextcloud Configs

[Reference Docs](<https://docs.nextcloud.com/server/stable/admin>*manual/configuration*database/linux*database*configuration.html)

The nextcloud docs specify some settings that they recommend for an optimal performance of nextcloud.

Let's edit `/etc/mysql/my.cnf`.

And add this section:

```
[mysqld]
transaction_isolation = READ-COMMITTED
binlog_format = ROW
```

Save the file and then restart mariabd.

Then create the database and a user for nextcloud:

```
CREATE DATABASE IF NOT EXISTS nc_db CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER 'nc_usr'@'localhost' IDENTIFIED BY 'password_here';
GRANT ALL PRIVILEGES ON nc_db.* TO 'nc_usr'@'localhost';
FLUSH PRIVILEGES;
EXIT; 
```

## PHP-FPM

Next after the database is PHP. Most guides start with the webserver first, but as php is kinda of a depenency for the webserver we make sure php is up and running before the webserver depends on it.

Well up and running? php is a skripting language so you call it when someone calls the website right?

Not in our setup because we use the FastCGI Process Manager for php which happens to run as a service. This service listens either on a port or socket for connections from the webserver. This is quite a performant solution.

So let's install. But for this we want the latest and greatest php and we only get that with an additional repository:

```
sudo apt install apt-transport-https lsb-release ca-certificates wget -y
sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg 
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" |sudo tee /etc/apt/sources.list.d/php.list
sudo apt update
```

Then install the package and the required php modules for nextcloud:

See the [Required Modules](<https://docs.nextcloud.com/server/stable/admin>*manual/installation/source*installation.html#prerequisites-for-manual-installation) page in the documentation for a list of all modules used.

```
sudo apt install php8.0-fpm -y
sudo apt install php8.0-curl php8.0-gd php8.0-mbstring php8.0-xml php8.0-zip php8.0-mysql php8.0-intl php8.0-gmp php8.0-imagick php8.0-bcmath -y
sudo apt install libmagickcore-6.q16-6-extra -y # if warning Module php-imagick in this instance has no SVG support. For better compatibility it is recommended to install it.
```

PHP-FPM knows pools which is a logic abstrahation for php. For nextcloud we create our own pool so that we can configure some settings and a custom socket.

The config file for our pool with it's contents: `/etc/php/8.0/fpm/pool.d/nextcloud.conf`

```
[nextcloud]
listen = /var/run/php8.0-fpm-nextcloud.sock
user = www-data
group = www-data
listen.owner = www-data
listen.group = www-data
; php.ini overrides
php_admin_value[disable_functions] = passthru,system
php_admin_value[memory_limit] = 2G
php_admin_value[upload_max_filesize] = 32G
php_admin_value[post_max_size] = 32G
php_admin_value[date.timezone] = Europe/Helsinki
php_admin_flag[allow_url_fopen] = off
; Choose how the process manager will control the number of child processes. 
pm = dynamic 
pm.max_children = 75 
pm.start_servers = 10 
pm.min_spare_servers = 5 
pm.max_spare_servers = 20 
pm.process_idle_timeout = 10s
; some environment variables
env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
```

[Reference Docs](<https://docs.nextcloud.com/server/stable/adminmanual/installation/sourceinstallation.html#php-fpm-configuration-notes)>

Then restart the service:

```
sudo rm /etc/php/8.0/fpm/pool.d/www.conf # Delete the default pool
sudo systemctl restart php8.0-fpm.service
```

## Nginx

Now that php is running we can configure the webserver. Although Nextcloud doesn't officially support nginx I still want to use nginx as it is a very performant webserver and integrates well with php-fpm.

Start by installing the package with systemd service:

```
sudo apt install nginx -y
# Manage the service 
sudo systemctl status nginx
sudo systemctl restart nginx
sudo systemctl stop nginx
sudo systemctl start nginx
```

### HTTPS

Before continuing to configure a virtualhost let's take a second and get a TLS certificate (which is used in the next step). Obtaining a TLS certificate was a nightmare until Let's Encrypt came to be. Now it's fairly simple with their `certbot`:

```
sudo apt install certbot python3-certbot-nginx -y
sudo certbot certonly --nginx -d nc.technat.ch --agree-tos -m technat@technat.ch
```

This obtains a certificate for our domain using the http-01 challenge and saves the certificate in `/etc/letsencrypt/live/nc.technat.ch/fullchain.pem`

Before continuing something to note: Let's Encrypt certificates are only valid for 90 days. To avoid an expired certificate we can automate the renewal similar to the way we obtained the cert:

Add the following cronjob to root using `sudo crontab -e `:

```
0 */12 * * * /usr/bin/certbot renew > /var/log/letsencrypt/certbot-renew.log
```

With this we can now continue to setup nginx.

### Virtualhost

Virtually any webserver uses virtualhosts for configuring multiple websites on one webserver. This isn't different for nextcloud. We place a virtualhost in `/etc/nginx/sites-available/nc.technat.ch`. The following one was taken 1:1 from the [docs](https://docs.nextcloud.com/server/stable/admin_manual/installation/nginx.html):

```
# source: https://docs.nextcloud.com/server/latest/admin_manual/installation/nginx.html
upstream php-handler {
    server unix:/var/run/php8.0-fpm-nextcloud.sock;
}

server {
    listen 80;
    listen [::]:80;
    server_name nc.technat.ch;

    # Enforce HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443      ssl http2;
    listen [::]:443 ssl http2;
    server_name nc.technat.ch;

    # Use Mozilla's guidelines for SSL/TLS settings
    # https://mozilla.github.io/server-side-tls/ssl-config-generator/
    ssl_certificate     /etc/letsencrypt/live/nc.technat.ch/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/nc.technat.ch/privkey.pem;


    # HSTS settings
    # WARNING: Only add the preload option once you read about
    # the consequences in https://hstspreload.org/. This option
    # will add the domain to a hardcoded list that is shipped
    # in all major browsers and getting removed from this list
    # could take several months.
    add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;" always;

    # set max upload size
    client_max_body_size 512M;
    fastcgi_buffers 64 4K;

    # Enable gzip but do not remove ETag headers
    gzip on;
    gzip_vary on;
    gzip_comp_level 4;
    gzip_min_length 256;
    gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
    gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

    # Pagespeed is not supported by Nextcloud, so if your server is built
    # with the `ngx_pagespeed` module, uncomment this line to disable it.
    #pagespeed off;

    # HTTP response headers borrowed from Nextcloud `.htaccess`
    add_header Referrer-Policy                      "no-referrer"   always;
    add_header X-Content-Type-Options               "nosniff"       always;
    add_header X-Download-Options                   "noopen"        always;
    add_header X-Frame-Options                      "SAMEORIGIN"    always;
    add_header X-Permitted-Cross-Domain-Policies    "none"          always;
    add_header X-Robots-Tag                         "none"          always;
    add_header X-XSS-Protection                     "1; mode=block" always;

    # Remove X-Powered-By, which is an information leak
    fastcgi_hide_header X-Powered-By;

    # Path to the root of your installation
    root /var/www/nc.technat.ch;

    # Specify how to handle directories -- specifying `/index.php$request_uri`
    # here as the fallback means that Nginx always exhibits the desired behaviour
    # when a client requests a path that corresponds to a directory that exists
    # on the server. In particular, if that directory contains an index.php file,
    # that file is correctly served; if it doesn't, then the request is passed to
    # the front-end controller. This consistent behaviour means that we don't need
    # to specify custom rules for certain paths (e.g. images and other assets,
    # `/updater`, `/ocm-provider`, `/ocs-provider`), and thus
    # `try_files $uri $uri/ /index.php$request_uri`
    # always provides the desired behaviour.
    index index.php index.html /index.php$request_uri;

    # Rule borrowed from `.htaccess` to handle Microsoft DAV clients
    location = / {
        if ( $http_user_agent ~ ^DavClnt ) {
            return 302 /remote.php/webdav/$is_args$args;
        }
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # Make a regex exception for `/.well-known` so that clients can still
    # access it despite the existence of the regex rule
    # `location ~ /(\.|autotest|...)` which would otherwise handle requests
    # for `/.well-known`.
    location ^~ /.well-known {
        # The rules in this block are an adaptation of the rules
        # in `.htaccess` that concern `/.well-known`.

        location = /.well-known/carddav { return 301 /remote.php/dav/; }
        location = /.well-known/caldav  { return 301 /remote.php/dav/; }

        location /.well-known/acme-challenge    { try_files $uri $uri/ =404; }
        location /.well-known/pki-validation    { try_files $uri $uri/ =404; }

        # Let Nextcloud's API for `/.well-known` URIs handle all other
        # requests by passing them to the front-end controller.
        return 301 /index.php$request_uri;
    }

    # Rules borrowed from `.htaccess` to hide certain paths from clients
    location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)(?:$|/)  { return 404; }
    location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console)                { return 404; }

    # Ensure this block, which passes PHP files to the PHP process, is above the blocks
    # which handle static assets (as seen below). If this block is not declared first,
    # then Nginx will encounter an infinite rewriting loop when it prepends `/index.php`
    # to the URI, resulting in a HTTP 500 error response.
    location ~ \.php(?:$|/) {
        fastcgi_split_path_info ^(.+?\.php)(/.*)$;
        set $path_info $fastcgi_path_info;

        try_files $fastcgi_script_name =404;

        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $path_info;
        fastcgi_param HTTPS on;

        fastcgi_param modHeadersAvailable true;         # Avoid sending the security headers twice
        fastcgi_param front_controller_active true;     # Enable pretty urls
        fastcgi_pass php-handler;

        fastcgi_intercept_errors on;
        fastcgi_request_buffering off;
    }

    location ~ \.(?:css|js|svg|gif|png|jpg|ico)$ {
        try_files $uri /index.php$request_uri;
        expires 6M;         # Cache-Control policy borrowed from `.htaccess`
        access_log off;     # Optional: Don't log access to assets
    }

    location ~ \.woff2?$ {
        try_files $uri /index.php$request_uri;
        expires 7d;         # Cache-Control policy borrowed from `.htaccess`
        access_log off;     # Optional: Don't log access to assets
    }

    # Rule borrowed from `.htaccess`
    location /remote {
        return 301 /remote.php$request_uri;
    }

    location / {
        try_files $uri $uri/ /index.php$request_uri;
    }
}
```

Note the following:

* The server_name `nc.technat.ch` needs to be replaced with the domain where this virtualhost will run
* The path to the certificate needs to be replaces as accordingly
* The web root path needs to be update accordingly
* The path to the certificate

Activate the virtualhost lile so:

```
sudo ln -s /etc/nginx/sites-available/nc.technat.ch /etc/nginx/sites-enabled/nc.technat.ch 
sudo systemctl restart nginx
```

## Initial Nextcloud setup

Now we are ready to setup nextcloud. Get the latest application into the specifed webroot, fix permissions and grant the nextcloud permissions to our data folder:

```
cd /tmp
wget https://download.nextcloud.com/server/releases/nextcloud-22.1.1.zip
sudo apt install unzip -y
unzip nextcloud-22.1.1.zip
mv nextcloud /var/www/nc.technat.ch
chown -R www-data:www-data /var/www/nc.technat.ch
chmod -R 770 /var/www/nc.technat.ch
chown -R www-data:www-data /nc-data
chmod -R 770 /nc-data
```

Now you can open your domain in a browser and configure the last settings:

* Admin Username: everything but not `admin`
* Admin Password: Long but not necessarily complex
* Data Folder: `/nc-data`
* DB User: `nc_db`
* DB PW: `password_here`
* DB: `nc_db`
* DB Host: `localhost:3306`

Congratulations! Your nextcloud is now ready to use!

## Post Setup

Although you are done now, it's highly recommended to configure some additional settings inside the Nextcloud UI and the config file.

### Security & setup warnings

In the admin settings overview page Nextcloud has a list of warnings and errors it checks for you. Fix what the suggest.

Some cases are listed in the sub chapters here.

#### Default Phone Region missing

Head over to the Nextcloud config file at `/var/www/nc.technat.ch/config.php` and add the following directive:

```
'default_phone_region' => 'CH',
"mysql.utf8mb4" => true,
```

### Memory Cache

To improve Nextcloud Performance it's recommended to add a [memcache](<https://docs.nextcloud.com/server/22/admin>*manual/configuration*server/caching_configuration.html). So here is how to install and configure `redis` as memcache for nextcloud:

```
sudo apt install redis-server php8.0-redis -y
```

We want redis to listen on a unix socket instead of a port. Update (comment, uncomment) the following lines in `/etc/redis/redis.conf`:

```
unixsocket /var/run/redis/redis-server.sock
unixsocketperm 770
port 0
# bind 127.0.0.1 ::1
```

Nginx needs access to that socket:

```
sudo usermod -a -G redis www-data
sudo systemctl restart redis-server
sudo systemctl restart nginx
```

And then for session handling we need to fix some php settings in `/etc/php/8.0/fpm/pool.d/nextcloud.conf`:

```
php_admin_value[redis.session.locking_enabled] = 1
php_admin_value[redis.session.lock_retries] = -1
php_admin_value[redis.session.lock_wait_time] = 10000
php_admin_value[session.save_handler] = redis
php_admin_value[session.save_path] = "unix:///var/run/redis/redis-server.sock"
```

And then add the following config values to your \`config.php\`:

```
'memcache.locking' => '\OC\Memcache\Redis',
'memcache.local' => '\OC\Memcache\Redis',
'memcache.distributed' => '\OC\Memcache\Redis',
'redis' => [
     'host'     => '/var/run/redis/redis-server.sock',
     'port'     => 0,
     'dbindex'  => 0,
     'password' => '',
     'timeout'  => 1.5,
],
```

Obviously all those changes need restart to the services:
```bash
sudo systemctl restart php8.0-fpm
sudo systemctl restart nginx
```

### Nextcloud jobs using cron

[Reference Docs](<https://docs.nextcloud.com/server/stable/admin>*manual/configuration*server/background*jobs*configuration.html)

Nextclouds runs some peridoc tasks. The most reliable way to run them is via cron.

To set this up add the following cron job with the command `crontab -u www-data -e`:

```
*/5  *  *  *  * php -f /var/www/nextcloud/cron.php
```

Note: The php-cli has it's own php.ini in `/etc/php/8.0/cli/php.ini `so you might want to add keys like `date.timezone` there as well according to the php-fpm config.

### SSMTP config

Source: <https://www.debiantutorials.com/installing-ssmtp-mta-mail-transfer-agent/>

* Add \`MAILTO="technat@technat.ch" to the top of the crontab file of root and www-data\`
* Install `ssmtp` pkg
* Edit config at `/etc/ssmtp/ssmtp.conf`:

  ```
  #
  # Config file for sSMTP sendmail
  #
  root=technat@technat.ch
  mailhub=mail.cyon.ch:465
  UseSTARTTLS=Yes
  AuthUser=regenwurm@technat.ch
  AuthPass="password_here"
  hostname=nc.technat.ch
  # Are users allowed to set their own From: address?
  # YES - Allow the user to specify their own From: address
  # NO - Use the system generated From: address
  FromLineOverride=YES
  
  ```

## Nextcloud Admin UI Settings

### Security

#### 2FA

Install from app store: Two-Factor Gateway, Two-Factor TOTP Provider

Enfore 2FA: true Enforced for groups: admin Not enforced for groups: none

#### Password Policies

* Min Password lenght: 14
* User password history: 24
* Number of days until user password expires: 90
* Number of login attemps before the user account is blocked: 10
* forbid common passwords: true
* enfore upper and lower case characters: false
* enfore numeric characters: false
* enfore special characters: false
* check passwords against... : true

### GeoBlocker

Install app from app store: true

Service to use: GeoIPLookup Install it like that ([docs](https://github.com/HomeITAdmin/nextcloud_geoblocker/)):

```
sudo apt-get install geoip-bin geoip-database -y
```

Note: `exec` php function must be enabled

All countries are block expect:

* Switzerland (CH)

Log attempts with:

* IP
* Country Code
* username

Delay login attempt:

* activate delaying
* activate blocking

Note: We don't enfore special characters for our passwords. This is because complexity doesn't help against DDOS, it's the number of characters that has the biggest impact on number of combinations.