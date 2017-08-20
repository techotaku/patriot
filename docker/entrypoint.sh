#!/bin/bash

export PYTHONUNBUFFERED=1

if [ -z "$PUBLIC_IP" ]; then
    export PUBLIC_IP=`curl -s https://ipconfig.io`
fi

mkdir -p /etc/patriot/ca
mkdir -p /etc/patriot/ssl
mkdir -p /etc/patriot/nginx
mkdir -p /run/nginx

IP_FORWARD_ENABLE=`sysctl -n net.ipv4.ip_forward`
if [ "$IP_FORWARD_ENABLE" -eq "0" ]; then
    echo "[Error] IP forward disabled. On host, execute below commands:"
    echo "        echo \"net.core.default_qdisc = fq\" | sudo tee -a /etc/sysctl.conf"
    echo "        sysctl -p"
else
    echo "[Info] IP forward enable."
fi

# Enable NAT forwarding
iptables -t nat -A POSTROUTING -j MASQUERADE || echo "No permission to operate iptables."
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu || echo "Run container with option \"--cap-add=NET_ADMIN\"."

# Enable TUN device
if [ ! -e /dev/net/tun ]; then
    mkdir -p /dev/net
    mknod /dev/net/tun c 10 200
    chmod 600 /dev/net/tun
fi

# Internal ports

export NGINX_HTTPS_INTERNAL_PORT=20443
export V2RAY_HTTP_INTERNAL_PORT=23080
export SSR_INTERNAL_PORT=24443
export OCSERV_INTERNAL_PORT=22443

# Certs

if [ ! -f "/etc/patriot/ssl/dh2048.pem" ]; then
    openssl dhparam -out /etc/patriot/ssl/dh2048.pem 2048
fi

if [ -z "$V2RAY_WEBSOCKET_CERT" ]; then
    export V2RAY_WEBSOCKET_CERT=/etc/patriot/ssl/v2ray.ws.crt.pem
fi

if [ -z "$V2RAY_WEBSOCKET_KEY" ]; then
    export V2RAY_WEBSOCKET_KEY=/etc/patriot/ssl/v2ray.ws.key.pem
fi

if [ -z "$V2RAY_WEBSOCKET_CA" ]; then
    export V2RAY_WEBSOCKET_CA=/etc/patriot/ssl/v2ray.ws.ca.pem
fi

if [ -z "$OCSERV_CERT" ]; then
    export OCSERV_CERT=/etc/patriot/ssl/ocserv.crt.pem
fi

if [ -z "$OCSERV_KEY" ]; then
    export OCSERV_KEY=/etc/patriot/ssl/ocserv.key.pem
fi

if [ -z "$OCSERV_CA" ]; then
    export OCSERV_CA=/etc/patriot/ssl/ocserv.ca.pem
fi

if [ ! -f "$V2RAY_WEBSOCKET_CERT" ] && [ -f "$V2RAY_WEBSOCKET_KEY" ]; then
    echo "[Warn] V2Ray WebSocket - Key exists but cert not, will re-generate."
    rm -f "$V2RAY_WEBSOCKET_KEY" > /dev/null 2>&1
fi

if [ ! -f "$V2RAY_WEBSOCKET_KEY" ] && [ ! -z "$V2RAY_HTTP_WEBSOCKET_DOMAIN" ]; then
    rm -f "$V2RAY_WEBSOCKET_CERT" > /dev/null 2>&1
    rm -f "$V2RAY_WEBSOCKET_KEY" > /dev/null 2>&1
    gencert.sh "/etc/patriot/ca" "Patriot" "${V2RAY_HTTP_WEBSOCKET_DOMAIN}"
    ln -s "/etc/patriot/ca/${V2RAY_HTTP_WEBSOCKET_DOMAIN}.crt.pem" "$V2RAY_WEBSOCKET_CERT"
    ln -s "/etc/patriot/ca/${V2RAY_HTTP_WEBSOCKET_DOMAIN}.key.pem" "$V2RAY_WEBSOCKET_KEY"
    ln -s "/etc/patriot/ca/ca.crt.pem" "$V2RAY_WEBSOCKET_CA"
fi

if [ ! -f "$OCSERV_CERT" ] && [ -f "$OCSERV_KEY" ]; then
    echo "[Warn] OCserv - Key exists but cert not, will re-generate."
    rm -f "$OCSERV_KEY" > /dev/null 2>&1
fi

if [ ! -f "$OCSERV_KEY" ] && [ ! -z "$OCSERV_DOMAIN" ]; then
    rm -f /etc/patriot/ssl/ocserv.crt.pem > /dev/null 2>&1
    gencert.sh "/etc/patriot/ca" "Patriot" "${OCSERV_DOMAIN}"
    ln -s "/etc/patriot/ca/${OCSERV_DOMAIN}.crt.pem" "$OCSERV_CERT"
    ln -s "/etc/patriot/ca/${OCSERV_DOMAIN}.key.pem" "$OCSERV_KEY"
    if [ ! -f "$OCSERV_CA" ]; then
        rm -f "$OCSERV_CA" > /dev/null 2>&1
        ln -s "/etc/patriot/ca/ca.crt.pem" "$OCSERV_CA"
    fi
fi

# Nginx

if [ -z "$NGINX_HTTPS_REDIRECT" ]; then
    export NGINX_HTTPS_REDIRECT=https://www.bing.com
fi

if [ ! -z "$NGINX_RESOLVER" ] && [ -z "$NGINX_SSL_STAPLING" -a -f "$V2RAY_WEBSOCKET_CA" ]; then
    export NGINX_SSL_STAPLING=On
fi

if [ -z "$NGINX_PHPFPM" ]; then
    export NGINX_PHPFPM=php
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
    export V2RAY_CLIENTS=`cat "${V2RAY_CLIENTS}"`
fi

# OCserv

if [ -z "$OCSERV_DNS" ]; then
    export OCSERV_DNS=8.8.8.8
fi

if [ -z "$OCSERV_SUBNET" ]; then
    export OCSERV_SUBNET=10.10.51.0
fi

if [ -z "$OCSERV_NETMASK" ]; then
    export OCSERV_NETMASK=255.255.255.0
fi

# SSR

if [ -z "$SSR_API_INTERFACE" ]; then
    export SSR_SINGLE_USER=On
    export SSR_API_INTERFACE=mudbjson
fi

if [ -z "$SSR_SINGLE_PORT_PWD" ]; then
    export SSR_SINGLE_PORT_PWD=atgwwc
fi

if [ ! -z "$SSR_SINGLE_USER" ]; then
    if [ -z "$SSR_SINGLE_USER_ID" ]; then
        export SSR_SINGLE_USER_ID=198709
    fi
    if [ -z "$SSR_SINGLE_USER_PWD" ]; then
        export SSR_SINGLE_USER_PWD=rEciTw
    fi
fi

if [ -z "$SSR_METHOD" ]; then
    export SSR_METHOD=none
fi

if [ -z "$SSR_PROTOCOL" ]; then
    export SSR_PROTOCOL=auth_chain_a
fi

if [ -z "$SSR_OBFS" ]; then
    export SSR_OBFS=tls1.2_ticket_auth
fi

if [ -z "$SSR_OBFS_DOMAIN" ]; then
    export SSR_OBFS_DOMAIN=mail.qq.com
fi

if [ -z "$SSR_DB_PORT" ]; then
    export SSR_DB_PORT=3306
fi

if [ -z "$SSR_DB_MUL" ]; then
    export SSR_DB_MUL=1.0
fi

if [ -z "$SSR_DB_SSL" ]; then
    export SSR_DB_SSL=0
fi

echo ""
echo "Updating ShadowsocksR configurations..."

rm -f /opt/shadowsocksr/userapiconfig.py > /dev/null 2>&1
rm -f /opt/shadowsocksr/user-config.json > /dev/null 2>&1
rm -f /opt/shadowsocksr/usermysql.json > /dev/null 2>&1
rm -f /opt/shadowsocksr/mudb.json > /dev/null 2>&1

cat /etc/mo/template/userapiconfig.py.template | mo > /opt/shadowsocksr/userapiconfig.py
cat /etc/mo/template/user-config.json.template | mo > /opt/shadowsocksr/user-config.json
cat /etc/mo/template/usermysql.json.template | mo > /opt/shadowsocksr/usermysql.json

if [ ! -z "$SSR_SINGLE_USER" ]; then
    cat /etc/mo/template/mudb.json.template | mo > /opt/shadowsocksr/mudb.json
else
    if [ -f "$SSR_MUDB_FILE" ]; then
        ln -s "$SSR_MUDB_FILE" /opt/shadowsocksr/mudb.json
    fi
fi

echo "Updating Nginx configurations..."
cat /etc/mo/template/default.conf.template | mo > /etc/nginx/conf.d/default.conf
cat /etc/mo/template/nginx.listen-ssl.template | mo > /etc/nginx/conf.d/listen-ssl
cat /etc/mo/template/nginx.php-param.template | mo > /etc/nginx/conf.d/php-param
cat /etc/mo/template/nginx.ssl-param.template | mo > /etc/nginx/conf.d/ssl-param
cat /etc/mo/template/nginx.ssl-param-with-shared-ca.template | mo > /etc/nginx/conf.d/ssl-param-with-shared-ca
cat /etc/mo/template/nginx.v2ray-websocket-param.template | mo > /etc/nginx/conf.d/v2ray-websocket-param

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
