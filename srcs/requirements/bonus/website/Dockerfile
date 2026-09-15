FROM alpine:3.23.5

RUN apk add --no-cache busybox-extras

COPY index.html /var/www/index.html

EXPOSE 80

CMD ["httpd", "-f", "-h", "/var/www"]
