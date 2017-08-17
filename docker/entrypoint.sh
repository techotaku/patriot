#!/bin/bash

if [ -z "$PUBLIC_IP" ]; then
    export PUBLIC_IP=`curl -s https://ipconfig.io`
fi

mkdir -p /etc/patriot/ca
mkdir -p /etc/patriot/ssl
mkdir -p /etc/patriot/nginx

# Internal ports

export NGINX_HTTPS_INTERNAL_PORT=20443
export V2RAY_HTTP_INTERNAL_PORT=23080
export SSR_INTERNAL_PORT=24443
export OCSERV_INTERNAL_PORT=22443

# Certs

if [ ! -f "/etc/patriot/ssl/dh2048.pem" ]; then
    openssl dhparam -out /etc/patriot/ssl/dh2048.pem 2048
fi

if [ ! -f "/etc/patriot/ssl/v2ray.ws.key.pem" ] && [ ! -z "$V2RAY_HTTP_WEBSOCKET_DOMAIN" ]; then
    rm -f /etc/patriot/ssl/v2ray.ws.crt.pem > /dev/null 2>&1
    rm -f /etc/patriot/ssl/v2ray.ws.ca.pem > /dev/null 2>&1
    gencert.sh "/etc/patriot/ca" "Patriot" "${V2RAY_HTTP_WEBSOCKET_DOMAIN}"
    ln -s "/etc/patriot/ca/${V2RAY_HTTP_WEBSOCKET_DOMAIN}.crt.pem" /etc/patriot/ssl/v2ray.ws.crt.pem
    ln -s "/etc/patriot/ca/${V2RAY_HTTP_WEBSOCKET_DOMAIN}.key.pem" /etc/patriot/ssl/v2ray.ws.key.pem
    ln -s "/etc/patriot/ca/ca.crt.pem" /etc/patriot/ssl/v2ray.ws.ca.pem
fi

if [ ! -f "/etc/patriot/ssl/ocserv.key.pem" ] && [ ! -z "$OCSERV_DOMAIN" ]; then
    rm -f /etc/patriot/ssl/ocserv.crt.pem > /dev/null 2>&1
    gencert.sh "/etc/patriot/ca" "Patriot" "${OCSERV_DOMAIN}"
    ln -s "/etc/patriot/ca/${OCSERV_DOMAIN}.crt.pem" /etc/patriot/ssl/ocserv.crt.pem
    ln -s "/etc/patriot/ca/${OCSERV_DOMAIN}.key.pem" /etc/patriot/ssl/ocserv.key.pem
    if [ ! -f "/etc/patriot/ssl/ocserv.ca.pem" ]; then
        ln -s "/etc/patriot/ca/ca.crt.pem" /etc/patriot/ssl/ocserv.ca.pem
    fi
fi

# Nginx

if [ ! -z "$NHINX_RESOLVER" ] && [ -z "$NHINX_SSL_STAPLING" -a -f "/etc/patriot/ssl/v2ray.ws.ca.pem" ]; then
    export NHINX_SSL_STAPLING=On
fi

if [ -z "$NGINX_HTTPS_DOMAINS" ]; then
    export NGINX_HTTPS_DOMAINS=www.bing.com
fi

if [ -z "$NGINX_HTTPS_REDIRECT" ]; then
    export NGINX_HTTPS_REDIRECT=https://www.bing.com
fi

# V2Ray

if [ -z "$V2RAY_CLIENTS" ] || [ ! -f "$V2RAY_CLIENTS" ]; then
    if [ -z "$V2RAY_SINGLE_USER_UUID"]; then
        export V2RAY_SINGLE_USER_UUID=`cat /proc/sys/kernel/random/uuid`
        echo "[Info] New UUID generated: ${V2RAY_SINGLE_USER_UUID}."
    fi
    export V2RAY_SINGLE_USER=On
    export V2RAY_CLIENTS="{ \"id\": \"${V2RAY_SINGLE_USER_UUID}\", \"alterId\": 32, \"level\": 1 }"
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

#export

echo ""
echo "Updating userapiconfig.py..."
cat /etc/patriot/template/userapiconfig.py.template | mo > /opt/shadowsocksr/userapiconfig.py

echo "Updating user-config.json..."
cat /etc/patriot/template/user-config.json.template | mo > /opt/shadowsocksr/user-config.json

if [ ! -z "$SSR_SINGLE_USER" ]; then
    echo "Updating mudb.json..."
    cat /etc/patriot/template/mudb.json.template | mo > /opt/shadowsocksr/mudb.json
fi

echo "Updating usermysql.json..."
cat /etc/patriot/template/usermysql.json.template | mo > /opt/shadowsocksr/usermysql.json

echo "Updating nginx default.conf..."
cat /etc/patriot/template/default.conf.template | mo > /etc/nginx/conf.d/default.conf

echo "Updating v2ray config.websocket.json..."
mkdir -p /etc/v2ray
cat /etc/patriot/template/config.websocket.json.template | mo > /etc/v2ray/config.websocket.json

echo "Updating ocserv.conf..."
mkdir -p /etc/ocserv
cat /etc/patriot/template/ocserv.conf.template | mo > /etc/ocserv/ocserv.conf

echo "Updating haproxy.cfg..."
cat /etc/patriot/template/haproxy.cfg.template | mo > /etc/haproxy/haproxy.cfg

echo "Updating supervisord.conf..."
mkdir -p /etc/supervisord
cat /etc/patriot/template/supervisord.conf.template | mo > /etc/supervisord/supervisord.conf

exec supervisord --nodaemon --configuration /etc/supervisord/supervisord.conf "$@"