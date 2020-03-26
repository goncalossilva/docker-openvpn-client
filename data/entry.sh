#!/bin/sh

################################################################################

config_file=$(ls -1 /data/vpn/*.conf 2>/dev/null | head -1)
if [ -z $config_file ]; then
    >&2 echo "[ERRO] No configuration file found. Please check your mount and file permissions. Exiting."
    exit 1
fi

LOG_LEVEL=${LOG_LEVEL:-3}
if ! $(echo $LOG_LEVEL | grep -Eq '^([1-9]|1[0-1])$'); then
    echo "[WARN] Invalid log level $LOG_LEVEL. Setting to default."
    LOG_LEVEL=3
fi

echo -e "\n---- Details ----"
echo "Using configuration file: $config_file"
echo "Using OpenVPN log level: $LOG_LEVEL"

################################################################################

echo -e "\n---- OpenVPN and Tinyproxy ----"

# These configuration file changes are required by Alpine.
echo "Making changes to the configuration file."
sed -i \
    -e '/up /c up \/etc\/openvpn\/up.sh' \
    -e '/down /c down \/etc\/openvpn\/down.sh' \
    -e 's/^proto udp$/proto udp4/' \
    -e 's/^proto tcp$/proto tcp4/' \
    $config_file

if ! grep -q 'pull-filter ignore "route-ipv6"' $config_file; then
    printf '\npull-filter ignore "route-ipv6"' >> $config_file
fi

if ! grep -q 'pull-filter ignore "ifconfig-ipv6"' $config_file; then
    printf '\npull-filter ignore "ifconfig-ipv6"' >> $config_file
fi

cp /data/vpn/* /etc/openvpn

echo "[INFO] Changes made and files moved into place."

################################################################################

# start list of commands to run Tinyproxy
# https://www.gnu.org/software/bash/manual/html_node/Command-Grouping.html
{
    echo "[INFO] Running tinyproxy"
    # Wait for VPN connection to be established
    while ! ping -c 1 1.1.1.1 > /dev/null 2&>1; do
        sleep 1
    done

    addr_eth=$(hostname -i)
    addr_tun=$(ip a show dev tun0 | grep inet | cut -d " " -f 6 | cut -d "/" -f 1)
    TINYPROXY_PORT=${TINYPROXY_PORT:-8888}

    sed -i \
        -e "/Port/c Port $TINYPROXY_PORT" \
        -e "/Listen/c Listen $addr_eth" \
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
} &

cd /etc/openvpn

openvpn --verb $LOG_LEVEL --auth-nocache --config $config_file
