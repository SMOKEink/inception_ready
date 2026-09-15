FROM alpine:3.23.5

RUN apk add --no-cache php84 php84-session php84-mysqli \
    && mkdir -p /var/www/adminer \
    && wget -O /var/www/adminer/index.php https://github.com/vrana/adminer/releases/download/v6.0.2/adminer-6.0.2.php

EXPOSE 8080

CMD ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/adminer"]
