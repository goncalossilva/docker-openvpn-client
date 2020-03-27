FROM alpine:3.10
LABEL maintainer="Gonçalo Silva <goncalossilva@gmail.com>"

RUN \
    apk add --no-cache \
        openvpn \
        tinyproxy && \
    mkdir -p /data/ /var/log/openvpn

ADD openvpn/ /etc/openvpn/
ADD tinyproxy /etc/tinyproxy/
ADD scripts /etc/scripts/

HEALTHCHECK CMD /etc/scripts/healthcheck.sh

ENTRYPOINT ["/etc/openvpn/start.sh"]
