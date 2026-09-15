# Developer documentation

## Prerequisites

- A Linux virtual machine with:
  Docker Engine, the Docker Compose plugin (`docker compose version`),
  `make`, `sudo`.
- The user must be allowed to run Docker (member of the `docker` group).
- `/etc/hosts` contains `127.0.0.1 aachata.42.fr`.

## Repository layout

```
Makefile                 entrypoint (wraps docker compose)
secrets/                 one password per file, ignored by git
srcs/.env                non-secret configuration (domain, names, emails)
srcs/docker-compose.yml  services, network, volumes, secrets
srcs/requirements/
    mariadb/    Dockerfile, tools/init-mariadb.sh
    wordpress/  Dockerfile, conf/www.conf, conf/memory.ini, tools/init.sh
    nginx/      Dockerfile, conf/default.conf
    bonus/
        adminer/    Dockerfile
        website/    Dockerfile, index.html
        portainer/  Dockerfile
```

## Setting up from scratch

1. Clone the repository.
2. Check `srcs/.env` (domain name, database name, WordPress user names and
   emails). The WordPress admin username must not contain "admin".
3. Create the secrets (the directory is in `.gitignore`):
   ```
   mkdir -p secrets
   echo 'a-root-password'      > secrets/db_root_password.txt
   echo 'a-db-password'        > secrets/db_password.txt
   echo 'a-wp-admin-password'  > secrets/wp_admin_password.txt
   echo 'a-wp-user-password'   > secrets/wp_user_password.txt
   echo 'a-portainer-password' > secrets/portainer_password.txt   # 12+ chars
   ```
4. `make`

## Makefile targets

| Target        | Runs                                                              |
|---------------|-------------------------------------------------------------------|
| `make` / `up` | `mkdir -p /home/aachata/data/{mariadb,wordpress}` then `docker compose up -d --build` |
| `down`        | `docker compose down` (containers + network removed, volumes kept) |
| `ps`          | `docker compose ps`                                               |
| `logs`        | `docker compose logs -f`                                          |
| `clean`       | `down` + remove the built images                                  |
| `fclean`      | `clean` + remove the volumes + `sudo rm -rf /home/aachata/data`   |
| `re`          | `fclean` then `up`                                                |

All compose commands use `-f srcs/docker-compose.yml`; the project name is
fixed to `inception` in the compose file, so `docker compose -f
srcs/docker-compose.yml ...` works from any directory.

## Useful commands

```
docker compose -f srcs/docker-compose.yml ps            # state of the containers
docker compose -f srcs/docker-compose.yml build nginx   # rebuild one image
docker compose -f srcs/docker-compose.yml up -d nginx   # recreate one service
docker compose -f srcs/docker-compose.yml restart nginx
docker exec -it wordpress sh                            # shell in a container
docker exec -it mariadb mariadb -u root -p              # database shell (root)
docker exec wordpress wp user list --allow-root --path=/var/www/html
docker volume ls ; docker volume inspect inception_wordpress
docker network inspect inception
docker images
```

## How a service starts

- `mariadb`: `init.sh` runs once when `/var/lib/mysql/mysql` does not exist:
  `mariadb-install-db`, then `mariadbd --bootstrap` with the SQL that sets the
  root password, creates the database and the WordPress user. Then
  `exec mariadbd`.
- `wordpress`: `init.sh` runs once when `wp-config.php` does not exist:
  WP-CLI downloads WordPress, writes `wp-config.php`, installs the site and
  creates the second user. Then `exec php-fpm84 -F`.
- `nginx`: the self-signed certificate is generated at build time;
  `nginx -g "daemon off;"` is the main process.
- Bonus: `php -S` (Adminer), BusyBox `httpd -f` (static site),
  `./portainer --admin-password-file` (Portainer).

Compose starts `wordpress` only when the `mariadb` healthcheck passes, and
`nginx` after `wordpress`, `adminer` and `website` (nginx resolves their
names at startup).

## Data and persistence

| Data                | Volume                | Host directory                   | Mounted in            |
|---------------------|-----------------------|----------------------------------|-----------------------|
| Database files      | `inception_mariadb`   | `/home/aachata/data/mariadb`     | `mariadb:/var/lib/mysql` |
| WordPress files     | `inception_wordpress` | `/home/aachata/data/wordpress`   | `wordpress:/var/www/html` and `nginx:/var/www/html` |

Both are Docker named volumes (`local` driver, `bind` option) whose storage is
the host directory, as required by the subject. `docker compose down` and a
machine reboot keep the data; only `make fclean` / `make re` delete it. The
init scripts detect an already initialised volume and skip the setup, so the
site and its content survive restarts and rebuilds.

Portainer keeps its own state inside its container (not precious: the admin
account is recreated from the secret on a fresh start).

## Changing the configuration

- Ports: edit `ports:` in `docker-compose.yml` (for example `"8443:443"`),
  or the `listen` directive in `srcs/requirements/nginx/conf/default.conf`
  together with the container side of the mapping. Then `make`.
- PHP-FPM port: `listen` in `wordpress/conf/www.conf` and `fastcgi_pass` in
  `nginx/conf/default.conf`. Then `make`.
- Domain: `DOMAIN_NAME` in `.env`, `server_name` and the certificate `-subj`
  in the nginx Dockerfile, `/etc/hosts`. WordPress stores the URL in its
  database, so a domain change needs `make re`.
