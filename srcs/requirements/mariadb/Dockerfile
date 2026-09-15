FROM alpine:3.23.5

RUN apk add --no-cache mariadb mariadb-client \
    && mkdir -p /run/mysqld \
    && chown mysql:mysql /run/mysqld

COPY tools/init-mariadb.sh /init-mariadb.sh

EXPOSE 3306

ENTRYPOINT ["sh", "/init-mariadb.sh"]
