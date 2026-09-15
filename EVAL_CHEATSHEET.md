# Inception: defense cheat sheet (aachata)

Only what you need. Read top to bottom once, then use it as a checklist.

## 0. Versions in the project (say them confidently)

| Thing      | Version / value                                     |
|------------|-----------------------------------------------------|
| Base image | `alpine:3.23.5` (3.24 is the latest stable, so 3.23 is the penultimate) |
| MariaDB    | 11.4 (Alpine package)                               |
| PHP        | 8.4 (`php84`, `php-fpm84`)                          |
| NGINX      | 1.28                                                |
| WordPress  | latest at install time (7.1 when tested), via WP-CLI 2.12.0 |
| Adminer    | 6.0.2 (single PHP file)                             |
| Portainer  | CE 2.45.0                                           |

Check https://alpinelinux.org/releases the morning of the defense. If a 3.25
exists, change `FROM alpine:3.23.5` to the latest 3.24.x in all 6 Dockerfiles.

## 1. Before the evaluator arrives (on the VM)

1. `/etc/hosts` has `127.0.0.1 aachata.42.fr`.
2. `secrets/` exists with the 5 files. Keep a backup copy outside the repo
   (e.g. `~/secrets_backup/`), because `git clone` will not bring it.
3. `git ls-files | grep -i secret` prints nothing (secrets are not committed).
4. Full rehearsal, exactly like the eval:
   ```
   docker stop $(docker ps -qa); docker rm $(docker ps -qa); docker rmi -f $(docker images -qa); docker volume rm $(docker volume ls -q); docker network rm $(docker network ls -q) 2>/dev/null
   mkdir eval && cd eval && git clone <repo-url> inception && cd inception
   cp -r ~/secrets_backup secrets
   make
   ```
   Then open https://aachata.42.fr, /adminer/, /website/, and :9443.
5. Rehearse the reboot: `sudo reboot`, then `make`, site still there with data.
6. Know the 5 passwords by heart or have `secrets/` open in a terminal.

## 2. The evaluation, step by step

### Preliminaries (they read files)
- `docker-compose.yml`: no `network: host`, no `links:`, has `networks:`. Yes.
- Makefile/scripts: no `--link`. Yes.
- Dockerfiles/scripts: no `tail -f`, `sleep infinity`, `while true`, no `&`.
  Every container ends in `exec <daemon>` or a direct `CMD`. Show it.
- They run the cleanup command, then `make`. First build takes 2 to 4 minutes.

### Activity overview (talk, no commands)
See section 3, questions 1 to 4.

### README / USER_DOC / DEV_DOC
Files exist at the repo root. README first line is italic with your login.

### Simple setup
- `https://aachata.42.fr` shows the site (title "Inception", not the install page).
- `http://aachata.42.fr` fails (port 80 not open, nothing listens).
- Padlock icon > certificate: self-signed, CN = aachata.42.fr, warning is normal.

### Docker basics
```
docker images            # names = service names: mariadb wordpress nginx adminer website portainer
docker compose -f srcs/docker-compose.yml ps      # or: make ps
```
One Dockerfile per service, all start with `FROM alpine:3.23.5`.

### Docker network
```
docker network ls        # inception
docker network inspect inception   # the 6 containers with their IPs
```

### NGINX
```
curl -I http://aachata.42.fr          # connection refused
curl -kI https://aachata.42.fr        # HTTP/1.1 200
openssl s_client -connect aachata.42.fr:443 -tls1_1   # rejected
openssl s_client -connect aachata.42.fr:443 -tls1_2   # works
openssl s_client -connect aachata.42.fr:443           # negotiates TLSv1.3
```
Or in the browser: padlock > connection is secure > TLS 1.3.

### WordPress
```
docker volume ls
docker volume inspect inception_wordpress   # "device": "/home/aachata/data/wordpress"
```
- Log in as `guest` (password: `secrets/wp_user_password.txt`) at
  https://aachata.42.fr/wp-login.php, open the "Hello world!" post, comment.
  It appears immediately (guest is an editor).
- Log out, log in as `aachata` (password: `secrets/wp_admin_password.txt`),
  Pages > Sample Page > edit title > Update > open the page on the site.

### MariaDB
```
docker volume inspect inception_mariadb     # "device": "/home/aachata/data/mariadb"
docker exec -it mariadb mariadb -u root -p  # password: secrets/db_root_password.txt
SHOW DATABASES; USE wordpress; SHOW TABLES; SELECT user_login FROM wp_users; EXIT;
```
Also possible as the WordPress user: `docker exec -it mariadb mariadb -u wpuser -p wordpress`.

### Persistence
`sudo reboot`, log back in, `cd` to the project, `make`. Containers restart by
themselves anyway (`restart: always`); `make` only makes sure. Site, comment
and page edit are still there because the data lives in `/home/aachata/data`.

### Configuration modification (they choose, you type)
All recipes end with `make` (rebuilds what changed and recreates containers).

| They ask                         | You change                                                                 |
|----------------------------------|----------------------------------------------------------------------------|
| NGINX port 443 -> 8443           | compose: `"8443:443"`. Site at https://aachata.42.fr:8443 (links follow the port automatically). |
| NGINX listens on another port inside | `listen 8443 ssl;` in `nginx/conf/default.conf` and compose `"443:8443"` |
| PHP-FPM port 9000 -> 9001        | `listen = 9001` in `wordpress/conf/www.conf` and `fastcgi_pass wordpress:9001;` in nginx conf |
| MariaDB port 3306 -> 3307        | add `--port=3307` to the final `mariadbd` command in `mariadb/tools/init-mariadb.sh`, then `docker exec wordpress wp config set DB_HOST mariadb:3307 --allow-root --path=/var/www/html` |
| Portainer port 9443 -> 9444      | compose: `"9444:9443"`                                                     |
| Adminer port 8080 -> 8081        | Dockerfile CMD `0.0.0.0:8081` and `proxy_pass http://adminer:8081/;`       |
| Website port 80 -> 8080          | Dockerfile CMD `httpd -f -p 8080 -h /var/www` and `proxy_pass http://website:8080/;` |

Why NGINX port change needs nothing else: `wp-config.php` defines `WP_HOME`
and `WP_SITEURL` from the host the browser used (`$_SERVER['HTTP_HOST']`), so
links and redirects follow the port.

### Bonus
- Adminer: https://aachata.42.fr/adminer/ , System MySQL, Server `mariadb`,
  user `wpuser`, password `secrets/db_password.txt`, database `wordpress`.
- Static site: https://aachata.42.fr/website/ (HTML + CSS, one file, no PHP).
- Portainer: https://aachata.42.fr:9443 , user `admin`, password
  `secrets/portainer_password.txt`. Click "Get started", see the containers,
  open one, view its logs. Justification: a web UI to see containers, images,
  volumes, networks and logs of the stack, restart a service, without the CLI.
  Useful to monitor and debug this exact infrastructure.

## 3. Concept answers (short, in your words)

1. **Docker**: packages an app with its dependencies in an image; a container
   is a running instance, an isolated process on the host kernel (namespaces
   and cgroups). **Docker Compose**: one YAML file describes several containers,
   their network, volumes and secrets; one command starts them all in order.
2. **Image with vs without compose**: same image. Without compose you type
   `docker build` then `docker run` with all the flags (ports, volumes,
   network, env) by hand for each container. With compose the flags are in the
   file, compose builds, names, connects and starts everything.
3. **Docker vs VM**: a VM runs a full OS with its own kernel (GB, minutes to
   boot, strong isolation). A container shares the host kernel, contains only
   the app files (MB, starts in ms). Here: one VM, six containers inside it.
4. **Directory structure**: `Makefile` at the root drives everything; `srcs/`
   holds the compose file, `.env` and one folder per service under
   `requirements/` (Dockerfile + `conf/` + `tools/`); `secrets/` at the root,
   ignored by git. One place per concern, easy to find, easy to grade.
5. **Docker network**: `inception` is a bridge network. Each container gets a
   private IP and a DNS name equal to its service name (`mariadb`,
   `wordpress`...). Only ports in `ports:` are reachable from the host. `network:
   host` would remove isolation (forbidden).
6. **Named volume vs bind mount**: a bind mount is any host path mounted in a
   container, not managed by Docker. A named volume is created and listed by
   Docker (`docker volume ls`). The subject wants named volumes stored in
   `/home/aachata/data`, so the volumes use the `local` driver with the
   `bind` option: Docker-managed volumes whose storage is that directory.
7. **Secrets vs env variables**: env vars are visible to every process and in
   `docker inspect`. A secret is a file mounted in memory at
   `/run/secrets/<name>` only in the containers that declare it. `.env` holds
   names and the domain; every password is a secret, read with `cat` in the
   scripts. `secrets/` is in `.gitignore`.
8. **PID 1 / no `tail -f`**: the container lives as long as its main process.
   The daemon must be PID 1 to receive `docker stop` signals and exit cleanly.
   `tail -f` or `sleep infinity` keep a container alive with a dead service
   and hide crashes. My scripts do their setup then `exec` the daemon.
9. **Restart on crash**: `restart: always` in compose. Demo a real crash from
   inside: `docker exec nginx kill 1` then `make ps`, it is back in seconds.
   (`docker stop`/`docker kill` are manual stops: Docker ignores the policy
   for them on purpose.)
10. **Why `--allow-root` in WP-CLI**: the init script runs as root inside the
    container; WP-CLI refuses to run as root unless told. Files are then
    `chown`ed to `nobody`, the user PHP-FPM runs as.
11. **TLS 1.2/1.3 only**: `ssl_protocols TLSv1.2 TLSv1.3;` in the nginx conf.
    Only port 443 is published; there is no `listen 80` at all.
12. **Penultimate version**: Alpine 3.24 is the current stable, 3.23 the one
    before. The tag `3.23.5` is its latest patch release.
13. **`latest` tag**: forbidden for the base image; my `FROM` is pinned. The
    built images show tag `latest` only because compose tags what it builds
    that way; that is a tag on my own images, not a pulled image.
14. **Healthcheck / depends_on**: compose pings MariaDB every 5 s with the root
    password from the secret; `wordpress` starts only when MariaDB is
    `healthy`. No wait loop in the scripts.
15. **Why Alpine**: tiny images (8 to 240 MB), `apk` installs in seconds, fast
    rebuilds.

## 4. Each file in one or two lines

- `Makefile`: `make` = create `/home/aachata/data/{mariadb,wordpress}` then
  `docker compose up -d --build`. `down` stops, `clean` also removes images,
  `fclean` also removes volumes and data, `re` = fclean + up.
- `srcs/.env`: domain, DB name, DB user, WP title, WP admin user and email,
  second WP user and email. Loaded into `mariadb` and `wordpress` with
  `env_file`. No password inside.
- `srcs/docker-compose.yml`: project name `inception`; 6 services with
  `build`, `image` (= service name), `container_name`, network, volumes,
  secrets, `restart: always`; 2 volumes bound to `/home/aachata/data`; the
  network; the 5 secrets pointing to `../secrets/*.txt`.
- `mariadb/Dockerfile`: `apk add mariadb mariadb-client`, create the socket
  dir `/run/mysqld`, copy the init script, `ENTRYPOINT sh /init-mariadb.sh`.
- `mariadb/tools/init-mariadb.sh`: starts MariaDB with
  `--bind-address=0.0.0.0` so WordPress can connect over the network. It reads
  the two passwords from `/run/secrets`. If
  `/var/lib/mysql/mysql` is missing (first start): `mariadb-install-db`, then
  `mariadbd --bootstrap` with SQL on stdin (root password, database, user,
  grant). Then `exec mariadbd --user=mysql`.
- `wordpress/Dockerfile`: `apk add php84 php84-fpm` + extensions WordPress
  needs, download WP-CLI to `/usr/local/bin/wp`, copy pool config, memory
  config, script. `ENTRYPOINT sh /init.sh`.
- `wordpress/conf/www.conf`: PHP-FPM pool: user `nobody`, `listen = 9000`
  (TCP, all interfaces, instead of the default 127.0.0.1), process manager
  settings.
- `wordpress/conf/memory.ini`: `memory_limit = 256M` (WP-CLI needs it to
  extract the WordPress archive, and WordPress recommends it).
- `wordpress/tools/init.sh`: reads 3 secrets. If `wp-config.php` is missing:
  `wp core download`, `wp config create` (DB host `mariadb`, plus the
  `WP_HOME`/`WP_SITEURL` lines), `wp core install` (admin user), `wp user
  create` (second user, editor), `chown` to nobody. Then `exec php-fpm84 -F`.
- `nginx/Dockerfile`: `apk add nginx openssl`, generate a self-signed
  certificate (1 year, CN aachata.42.fr) at build time, copy the server
  config, `CMD nginx -g "daemon off;"`.
- `nginx/conf/default.conf`: `listen 443 ssl`, cert paths, `ssl_protocols
  TLSv1.2 TLSv1.3`, root `/var/www/html` (the WordPress volume), `.php` goes
  to `fastcgi_pass wordpress:9000`, `/adminer/` and `/website/` are
  `proxy_pass` to the bonus containers.
- `bonus/adminer/Dockerfile`: `php84 + mysqli + session`, download
  `adminer-6.0.2.php` as `index.php`, `CMD php -S 0.0.0.0:8080`.
- `bonus/website/Dockerfile` + `index.html`: `busybox-extras` gives `httpd`;
  `CMD httpd -f -h /var/www` serves the page on port 80 in the foreground.
- `bonus/portainer/Dockerfile`: download and extract the official Portainer
  release tarball, `WORKDIR /portainer`, `CMD ./portainer
  --admin-password-file /run/secrets/portainer_password`. Needs
  `/var/run/docker.sock` mounted to talk to Docker. HTTPS on 9443 with its own
  self-signed certificate.

## 5. Questions they like to ask

- "Where are the passwords?" `secrets/`, one per file, gitignored, mounted at
  `/run/secrets/`. Show `docker exec wordpress ls /run/secrets`.
- "Why `ENTRYPOINT ["sh", "/init.sh"]` and not CMD?" Both work; ENTRYPOINT
  says "this script is the container". The script ends with `exec`, so the
  daemon replaces the shell as PID 1. Show `docker exec mariadb ps` (PID 1 =
  mariadbd).
- "What is `--bootstrap`?" Runs the SQL from stdin without opening the network,
  then exits. Used by MariaDB itself to create the system tables.
- "Why two WordPress users?" Subject rule. Admin `aachata` (name must not
  contain admin), plus `guest` (editor) who can log in and comment.
- "How does nginx reach PHP?" FastCGI over TCP to `wordpress:9000`; both
  containers mount the same volume at `/var/www/html`, nginx sends the script
  path, PHP-FPM executes it.
- "Why is the website served by busybox httpd?" Simplest static server
  available in Alpine, one binary, foreground with `-f`, no config file.
- "Why Portainer on its own port?" Its web UI does not work behind a
  sub-path; the bonus explicitly allows opening more ports.
- "What is `docker.sock`?" The Docker daemon's API socket. Portainer needs it
  to list and manage containers. It gives full Docker control, which is the
  point of a management UI.
- "What does `try_files` do?" Serve the file if it exists, otherwise hand the
  request to `index.php` (WordPress routing).
- "Why `chown -R nobody`?" PHP-FPM runs as `nobody`; WordPress must own its
  files to upload media and update itself.
- "What if I delete a container?" `docker rm -f wordpress` then `make`: it is
  recreated; the volume still has the files, `wp-config.php` exists, so the
  script skips the install and starts PHP-FPM.

## 6. If something goes wrong during the defense

| Symptom                                   | Do                                                                 |
|-------------------------------------------|--------------------------------------------------------------------|
| `make` fails on a missing secret file     | `ls secrets/`, copy the backup, `make` again                        |
| `nginx` is "Restarting" right after boot  | wait 5 s, it retries until wordpress/adminer/website resolve; `make ps` |
| Browser shows the WordPress install page  | first start was interrupted: `make re` (wipes data, 3 minutes)     |
| Port 443 already in use                   | `sudo ss -ltnp | grep 443`, stop that service, `make`              |
| Portainer says timed out                  | not applicable, admin is created from the secret at start; if the UI hangs: `docker restart portainer` |
| Need logs                                 | `make logs` or `docker logs <container>`                           |
