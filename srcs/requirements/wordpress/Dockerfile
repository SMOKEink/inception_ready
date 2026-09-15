FROM alpine:3.23.5

RUN apk add --no-cache php84 php84-fpm php84-phar php84-mysqli php84-curl \
        php84-mbstring php84-xml php84-fileinfo \
    && wget -O /usr/local/bin/wp https://github.com/wp-cli/wp-cli/releases/download/v2.12.0/wp-cli-2.12.0.phar \
    && chmod +x /usr/local/bin/wp

COPY conf/www.conf /etc/php84/php-fpm.d/www.conf
COPY tools/init-wordpress.sh /init-wordpress.sh

EXPOSE 9000

ENTRYPOINT ["sh", "/init-wordpress.sh"]