#!/bin/bash

export PYTHONUNBUFFERED=1

export GATEWAY_IP=`/sbin/ip route|awk '/default/ { print $3 }'`
echo "[Info] Gateway IP ${GATEWAY_IP} detected."

IP_FORWARD_ENABLE=`sysctl -n net.ipv4.ip_forward`
if [ "$IP_FORWARD_ENABLE" -eq "0" ]; then
    echo "[Error] IP forward disabled. On host, execute below commands:"
    echo "        echo \"net.core.default_qdisc = fq\" | sudo tee -a /etc/sysctl.conf"
    echo "        sysctl -p"
else
    echo "[Info] IP forward enabled."
fi

# Enable NAT forwarding
iptables -t nat -A POSTROUTING -j MASQUERADE || echo "[Error] No permission to operate iptables."
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu || echo "        Run container with option \"--cap-add=NET_ADMIN\"."

# Enable TUN device
if [ ! -e /dev/net/tun ]; then
    mkdir -p /dev/net
    mknod /dev/net/tun c 10 200
    chmod 600 /dev/net/tun
fi

# Internal ports

export CADDY_INTERNAL_PORT=20443
export V2RAY_HTTP_INTERNAL_PORT=20080
export OCSERV_INTERNAL_PORT=21443

# Caddy

mkdir -p /etc/patriot/caddy
mkdir -p /root/webroot

export CADDYPATH=/etc/patriot/caddy

if [ -z "$DEFAULT_REDIRECT" ]; then
    export DEFAULT_REDIRECT=https://www.bing.com
fi

# V2Ray

if [ -z "$V2RAY_SINGLE_USER_ALTER_ID" ]; then
    export V2RAY_SINGLE_USER_ALTER_ID=32
fi

if [ -z "$V2RAY_CLIENTS" ]; then
    mkdir -p /etc/patriot/v2ray
    export V2RAY_CLIENTS=/etc/patriot/v2ray/clients.json
fi

if [ ! -f "$V2RAY_CLIENTS" ]; then
    if [ -z "$V2RAY_SINGLE_USER_UUID"]; then
        export V2RAY_SINGLE_USER_UUID=`cat /proc/sys/kernel/random/uuid`
        echo "[Info] V2Ray - new UUID generated: ${V2RAY_SINGLE_USER_UUID}. Saved to ${V2RAY_CLIENTS}."
    fi
    export V2RAY_SINGLE_USER=On
    export V2RAY_CLIENTS_PATH="${V2RAY_CLIENTS}"
    export V2RAY_CLIENTS="{ \"id\": \"${V2RAY_SINGLE_USER_UUID}\", \"alterId\": ${V2RAY_SINGLE_USER_ALTER_ID}, \"level\": 1 }"
    echo "${V2RAY_CLIENTS}" > "${V2RAY_CLIENTS_PATH}"
else
    echo "[Info] V2Ray predefined user configuration detected."
    export V2RAY_CLIENTS=`cat "${V2RAY_CLIENTS}"`
fi

# OCserv

mkdir -p /etc/patriot/ca
mkdir -p /etc/patriot/ssl

if [ -z "$OCSERV_CERT" ]; then
    export OCSERV_CERT=${CADDYPATH}/acme/acme-v01.api.letsencrypt.org/sites/${SSL_DOMAIN}/${SSL_DOMAIN}.crt
fi

if [ -z "$OCSERV_KEY" ]; then
    export OCSERV_KEY=${CADDYPATH}/acme/acme-v01.api.letsencrypt.org/sites/${SSL_DOMAIN}/${SSL_DOMAIN}.key
fi

if [ -z "$OCSERV_CA" ]; then
    export OCSERV_CA=/etc/patriot/ssl/ocserv.ca.pem
fi

if [ -f "$OCSERV_CERT" ] && [ -f "$OCSERV_KEY" ]; then
    export OCSERV_READY="On"
fi

if [ ! -f "$OCSERV_CA" ]; then
    rm -f "$OCSERV_CA" > /dev/null 2>&1
    gencert.sh "/etc/patriot/ca" "Patriot" "${SSL_DOMAIN}"
    ln -s "/etc/patriot/ca/ca.crt.pem" "$OCSERV_CA"
fi

if [ -z "$OCSERV_DNS" ]; then
    export OCSERV_DNS=8.8.8.8
fi

if [ -z "$OCSERV_SUBNET" ]; then
    export OCSERV_SUBNET=10.10.51.0
fi

if [ -z "$OCSERV_NETMASK" ]; then
    export OCSERV_NETMASK=255.255.255.0
fi

if [ ! -z "$SSL_DOMAIN" ] && [ ! -z "$ACME_EMAIL" ]; then
    echo ""
    echo "Updating Caddy configurations..."
    cat /etc/mo/template/Caddyfile.template | mo > /etc/Caddyfile
    cat /etc/mo/template/index.html.template | mo > /root/webroot/index.html

    echo "Updating V2Ray configurations..."
    mkdir -p /etc/v2ray
    cat /etc/mo/template/config.websocket.json.template | mo > /etc/v2ray/config.websocket.json

    echo "Updating OCserv configuration..."
    mkdir -p /etc/ocserv
    cat /etc/mo/template/ocserv.conf.template | mo > /etc/ocserv/ocserv.conf

    echo "Updating HAProxy configuration..."
    cat /etc/mo/template/haproxy.cfg.template | mo > /etc/haproxy/haproxy.cfg

    echo "Updating Supervisord configuration..."
    mkdir -p /etc/supervisord
    cat /etc/mo/template/supervisord.conf.template | mo > /etc/supervisord/supervisord.conf

    echo "All configurations updated. Starting services..."
    exec supervisord --nodaemon --configuration /etc/supervisord/supervisord.conf "$@"
else
    echo ""
    echo "[Error] Environment variables \"SSL_DOMAIN\" and \"ACME_EMAIL\" are required."
fi
