# User documentation

## What the stack provides

| Address                          | What you get                                   |
|----------------------------------|------------------------------------------------|
| https://aachata.42.fr            | The WordPress website                          |
| https://aachata.42.fr/wp-admin   | WordPress administration panel                 |
| https://aachata.42.fr/adminer/   | Adminer, a web interface to the database       |
| https://aachata.42.fr/website/   | A static showcase website                      |
| https://aachata.42.fr:9443       | Portainer, a web interface to manage Docker    |

Only HTTPS is available (HTTP on port 80 is closed). The certificate is
self-signed, so the browser shows a warning the first time: accept it.
`aachata.42.fr` must point to the machine (`127.0.0.1 aachata.42.fr` in
`/etc/hosts`).

## Start and stop

Run these from the root of the project:

| Command      | Effect                                                         |
|--------------|----------------------------------------------------------------|
| `make`       | Build the images (if needed) and start all services            |
| `make down`  | Stop and remove the containers (data is kept)                  |
| `make re`    | Full reset: remove everything including data, then start again |

The first `make` takes a few minutes (packages and WordPress are downloaded).
The services start again automatically after a reboot of the machine.

## Accounts and credentials

Usernames are in `srcs/.env`, passwords are in the `secrets/` directory (one
file per password, never committed to git):

| Account                     | Username (from `.env`)  | Password file                    |
|-----------------------------|-------------------------|----------------------------------|
| WordPress administrator     | `WP_ADMIN_USER`         | `secrets/wp_admin_password.txt`  |
| WordPress second user       | `WP_USER` (editor role) | `secrets/wp_user_password.txt`   |
| Database user (WordPress)   | `MYSQL_USER`            | `secrets/db_password.txt`        |
| Database root               | `root`                  | `secrets/db_root_password.txt`   |
| Portainer                   | `admin`                 | `secrets/portainer_password.txt` |

To change a password: edit the secret file, then `make re` (the accounts are
created on the first start of an empty stack).

Adminer login: System `MySQL`, Server `mariadb`, Username `MYSQL_USER`,
Password from `secrets/db_password.txt`, Database `MYSQL_DATABASE`.

## Check that everything runs

```
make ps
```
All six containers must show `Up`, and `mariadb` must show `(healthy)`.

```
make logs          # follow the logs of every service (Ctrl+C to leave)
docker logs nginx  # logs of one service
```

Quick manual checks:
- https://aachata.42.fr shows the site, not the WordPress installation page.
- http://aachata.42.fr does not answer.
- `docker volume ls` shows `inception_mariadb` and `inception_wordpress`.
- `docker network ls` shows `inception`.
