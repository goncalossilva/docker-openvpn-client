#!/bin/sh

################################################################################

echo "[INFO] Starting tinyproxy"

addr_tun=$(ip a show dev tun0 | grep inet | cut -d " " -f 6 | cut -d "/" -f 1)

echo "Port: $TINYPROXY_PORT"
echo "Bind: $addr_tun"

sed -i \
    -e "/Port/c Port $TINYPROXY_PORT" \
    -e "/Bind/c Bind $addr_tun" \
    /etc/tinyproxy/tinyproxy.conf

if [ ! -z $TINYPROXY_USER ]; then
    if [ ! -z $TINYPROXY_PASS ]; then
        echo -e "\nBasicAuth $TINYPROXY_USER $TINYPROXY_PASS" >> /etc/tinyproxy/tinyproxy.conf
    else
        echo "[WARN] Tinyproxy username supplied without password. Starting without credentials."
    fi
fi

tinyproxy -c /etc/tinyproxy/tinyproxy.conf
