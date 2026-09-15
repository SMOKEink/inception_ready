FROM alpine:3.23.5

RUN wget -O /tmp/portainer.tar.gz https://github.com/portainer/portainer/releases/download/2.45.0/portainer-2.45.0-linux-amd64.tar.gz \
    && tar -xzf /tmp/portainer.tar.gz -C / \
    && rm /tmp/portainer.tar.gz

WORKDIR /portainer

EXPOSE 9443

CMD ["./portainer", "--admin-password-file", "/run/secrets/portainer_password"]
