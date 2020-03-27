#!/bin/sh

################################################################################

config_file=$(ls -1 /data/*.conf 2>/dev/null | head -1)
if [ -z $config_file ]; then
    >&2 echo "[ERROR] No configuration file found. Please check your mount and file permissions. Exiting."
    exit 1
fi

LOG_LEVEL=${LOG_LEVEL:-3}
if ! $(echo $LOG_LEVEL | grep -Eq '^([1-9]|1[0-1])$'); then
    echo "[WARN] Invalid log level $LOG_LEVEL. Setting to default."
    LOG_LEVEL=3
fi

echo "Using configuration file: $config_file"
echo "Using OpenVPN log level: $LOG_LEVEL"

################################################################################

# These configuration file changes are required by Alpine.
echo "Making changes to the configuration file."
sed -i \
    -e 's/^proto udp$/proto udp4/' \
    -e 's/^proto tcp$/proto tcp4/' \
    $config_file

if ! grep -q 'pull-filter ignore "route-ipv6"' $config_file; then
    printf '\npull-filter ignore "route-ipv6"' >> $config_file
fi

if ! grep -q 'pull-filter ignore "ifconfig-ipv6"' $config_file; then
    printf '\npull-filter ignore "ifconfig-ipv6"' >> $config_file
fi

cp /data/* /etc/openvpn

echo "[INFO] Changes made and files moved into place."

################################################################################

echo "Updating firewall"
TINYPROXY_PORT=${TINYPROXY_PORT:-8888}
iptables -I INPUT -p tcp --dport $TINYPROXY_PORT -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -I OUTPUT -p tcp --sport $TINYPROXY_PORT -m state --state ESTABLISHED -j ACCEPT

cd /etc/openvpn

openvpn --verb $LOG_LEVEL --auth-nocache --config $config_file \
    --up-delay --up /etc/tinyproxy/start.sh --down /etc/tinyproxy/stop.sh \
    --setenv TINYPROXY_PORT $TINYPROXY_PORT \
    --setenv TINYPROXY_USER $TINYPROXY_USER \
    --setenv TINYPROXY_PASS $TINYPROXY_PASS
