*This project has been created as part of the 42 curriculum by aachata.*

# Inception

## Description

Inception is a system administration project: a small web infrastructure built
with Docker and Docker Compose, where every service runs in its own container
built from a hand-written Dockerfile (no ready-made images).

The stack serves a WordPress website over HTTPS only:

| Service   | Role                                              | Part      |
|-----------|---------------------------------------------------|-----------|
| nginx     | Single entrypoint, TLS 1.2/1.3 on port 443        | mandatory |
| wordpress | WordPress + PHP-FPM (port 9000, internal only)    | mandatory |
| mariadb   | Database (port 3306, internal only)               | mandatory |
| website   | Static HTML/CSS site, at `/website/`              | bonus     |
| portainer | Docker management UI, on port 9443 (free choice)  | bonus     |

All images are built from `alpine:3.23.5` (penultimate stable release of Alpine).

## Instructions

Prerequisites: a Linux virtual machine with Docker Engine, the Docker Compose
plugin, `make` and `sudo`.

1. Point the domain to the machine (add to `/etc/hosts`):
   `127.0.0.1 aachata.42.fr`
2. Create the secret files (they are ignored by git), one password per file:
   ```
   secrets/db_root_password.txt
   secrets/db_password.txt
   secrets/wp_admin_password.txt
   secrets/wp_user_password.txt
   secrets/portainer_password.txt   (12 characters minimum)
   ```
3. Build and start everything: `make`
4. Open https://aachata.42.fr (self-signed certificate, accept the warning).

Other targets: `make down` (stop), `make logs`, `make ps`, `make clean`
(also remove images), `make fclean` (also remove volumes and data), `make re`.

See `USER_DOC.md` and `DEV_DOC.md` for details.

## Project description

### How Docker is used

- `Makefile` is the entrypoint: it creates the data directories under
  `${HOME}/data` and runs `docker compose`.
- `srcs/docker-compose.yml` declares the five services, the network, the two
  named volumes and the secrets. Each service points to its own Dockerfile in
  `srcs/requirements/<service>/` (bonus ones in `srcs/requirements/bonus/`).
- Each Dockerfile installs the software with `apk`, copies its configuration
  from `conf/` and, when the service needs a first-start setup, a small
  `tools/init.sh` script. The script ends with `exec <daemon>` so the daemon
  becomes PID 1 and receives the stop signals directly.
- Non-secret configuration lives in `srcs/.env` (domain, database name, user
  names). Passwords are Docker secrets, mounted read-only in
  `/run/secrets/<name>` inside the containers that need them.
- Containers restart automatically (`restart: always`).

### Main design choices

- Alpine instead of Debian: images are tiny (8 to 240 MB) and build in seconds.
- MariaDB is initialised once with `mariadb-install-db` and
  `mariadbd --bootstrap` (SQL fed on stdin, no server start/stop dance), then
  the real server is started with `exec`.
- WordPress is installed on first start with WP-CLI (`core download`,
  `config create`, `core install`, `user create`). The check "does
  `wp-config.php` exist" makes the script idempotent across restarts.
- Startup order is handled by Compose: MariaDB has a healthcheck and WordPress
  waits for it (`condition: service_healthy`), so no wait loop is needed in
  the scripts.
- NGINX terminates TLS and forwards `.php` requests to `wordpress:9000` over
  FastCGI. The bonus website is reverse-proxied under `/website/`, so port 443
  stays the only entrypoint. Portainer needs its own port (its web UI does not
  work under a sub-path), which the bonus allows.

### Virtual machines vs Docker

A VM emulates a full computer with its own kernel; each VM boots an entire OS
(gigabytes, minutes). A container is just an isolated process group that shares
the host kernel (namespaces + cgroups); it starts in milliseconds and its image
only contains the files the service needs. VMs give stronger isolation, Docker
gives density, speed and reproducible builds. Here Docker runs inside a VM: the
VM provides the Linux host, Docker provides one isolated environment per
service.

### Secrets vs environment variables

Environment variables are visible to every process in the container, appear in
`docker inspect` and are easy to leak in logs or in git through `.env`. Docker
secrets are files mounted in memory at `/run/secrets/`, only in the containers
that declare them, and are read at the exact moment they are needed. This
project keeps non-sensitive settings in `.env` and every password in
`secrets/` (ignored by git).

### Docker network vs host network

With `network_mode: host` a container shares the host network stack: no
isolation, every port it opens is open on the host, and two services cannot use
the same port. With a user-defined bridge network (the `inception` network),
containers get their own IP, reach each other by service name through Docker's
DNS (`mariadb`, `wordpress`...), and only the ports explicitly published with
`ports:` are reachable from outside. That is how NGINX can be the single entry
point while MariaDB and PHP-FPM stay private.

### Docker volumes vs bind mounts

A bind mount maps an arbitrary host path into the container; Docker does not
manage it and it depends on the host layout. A named volume is created and
managed by Docker (`docker volume ls/inspect`), has a stable name, and is the
recommended way to persist data. The subject requires named volumes whose data
lives in `${HOME}/data`, so the two volumes use the `local` driver with
the `bind` option: they are real Docker volumes (managed, inspectable, declared
in Compose) whose storage is that host directory.

## Resources

- Docker: Dockerfile reference and best practices, Compose file reference,
  volumes, secrets, networking (https://docs.docker.com)
- "Docker and the PID 1 zombie reaping problem" (why `exec` and no `tail -f`)
- Alpine Linux package index (https://pkgs.alpinelinux.org)
- MariaDB knowledge base: `mariadb-install-db`, bootstrap mode, `bind-address`
- WP-CLI documentation (https://developer.wordpress.org/cli/commands/)
- NGINX documentation: `ssl_protocols`, `fastcgi_pass`, `proxy_pass`
- PHP-FPM configuration (pool `listen`, `pm` settings)
- Portainer CE documentation (https://docs.portainer.io)

### AI usage

AI assistance was used to review the project documentation, clarify Docker and
Docker Compose concepts, troubleshoot service access and networking, and check
that the user and developer instructions matched the actual configuration. The
Dockerfiles, initialization scripts, Compose configuration, and application
configuration were written and verified as part of the project work.
