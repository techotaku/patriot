FROM alpine:3.6

MAINTAINER Ian Li <OpenSource@ianli.xyz>

ARG V2RAY_VER=2.34
ARG OC_VERSION=0.11.8

RUN apk add --no-cache bash curl nano ca-certificates bind-tools python py-pip nginx haproxy gnutls gnutls-utils && \
    sed -i "/error_log /{s/\/var\/log\/nginx\/error.log/\/dev\/stdout/}" /etc/nginx/nginx.conf && \
    apk add --no-cache --virtual .ocserv-runtime-dependencies iptables musl openssl readline libnl3 lz4 lz4-libs libseccomp libev geoip && \
    apk add --no-cache --virtual .ocserv-build-dependencies build-base unzip xz linux-headers musl-dev gnutls-dev readline-dev libnl3-dev lz4-dev libseccomp-dev libev-dev geoip-dev && \
    pip install supervisor supervisor-stdout && \
    curl -O https://raw.githubusercontent.com/tests-always-included/mo/master/mo && \
    mv mo /usr/local/bin && \
    chmod +x /usr/local/bin/mo && \
    curl -L "https://github.com/v2ray/v2ray-core/releases/download/v${V2RAY_VER}/v2ray-linux-64.zip" -o /tmp/v2ray.zip && \
    unzip /tmp/v2ray.zip -d /tmp/ && \
    mv /tmp/v2ray-v${V2RAY_VER}-linux-64/v2ray /usr/local/bin/v2ray && \
    chmod +x /usr/local/bin/v2ray && \
    rm -rf /tmp/v2ray* && \
    curl -L https://github.com/shadowsocksrr/shadowsocksr/archive/manyuser.zip -o /tmp/shadowsocksr.zip && \
    curl -L https://github.com/nakagami/CyMySQL/archive/master.zip -o /tmp/CyMySQL.zip && \
    unzip /tmp/shadowsocksr.zip -d /tmp/ && \
    unzip /tmp/CyMySQL.zip -d /tmp/ && \
    mv /tmp/CyMySQL-master/cymysql /tmp/shadowsocksr-manyuser/ && \
    rm -rf /tmp/CyMySQL-master && \
    mkdir -p /opt && \
    mv /tmp/shadowsocksr-manyuser /opt/shadowsocksr && \
    rm /tmp/shadowsocksr.zip /tmp/CyMySQL.zip && \
    mkdir /src && cd /src && \
    OC_FILE="ocserv-$OC_VERSION" && \
    wget ftp://ftp.infradead.org/pub/ocserv/$OC_FILE.tar.xz && \
    tar xJf $OC_FILE.tar.xz && \
    rm $OC_FILE.tar.xz && \
    cd $OC_FILE && \
    sed -i '/#define DEFAULT_CONFIG_ENTRIES /{s/96/200/}' src/vpn.h && \
    ./configure && \
    make -j"$(nproc)" && \
    make install && \
    mkdir -p /etc/ocserv && \
    cd .. && \
    rm -rf $OC_FILE && \
    cd / && \
    rm -rf /src && \
    apk del .ocserv-build-dependencies && \
    curl -L -O https://github.com/techotaku/patriot/raw/master/docker/entrypoint.sh && \
    curl -L -O https://github.com/techotaku/patriot/raw/master/docker/gencert.sh && \
    chmod +x entrypoint.sh && \
    mv entrypoint.sh /usr/local/bin/entrypoint.sh && \
    chmod +x gencert.sh && \
    mv gencert.sh /usr/local/bin/gencert.sh && \
    mkdir -p /etc/mo/template && \
    curl -L https://github.com/techotaku/patriot/raw/master/docker/template/config.websocket.json.template -o /etc/mo/template/config.websocket.json.template && \
    curl -L https://github.com/techotaku/patriot/raw/master/docker/template/default.conf.template -o /etc/mo/template/default.conf.template && \
    curl -L https://github.com/techotaku/patriot/raw/master/docker/template/nginx.listen-ssl.template -o /etc/mo/template/nginx.listen-ssl.template && \
    curl -L https://github.com/techotaku/patriot/raw/master/docker/template/nginx.php-param.template -o /etc/mo/template/nginx.php-param.template && \
    curl -L https://github.com/techotaku/patriot/raw/master/docker/template/nginx.ssl-param.template -o /etc/mo/template/nginx.ssl-param.template && \
    curl -L https://github.com/techotaku/patriot/raw/master/docker/template/nginx.ssl-param-with-shared-ca.template -o /etc/mo/template/nginx.ssl-param-with-shared-ca.template && \
    curl -L https://github.com/techotaku/patriot/raw/master/docker/template/nginx.v2ray-websocket-param.template -o /etc/mo/template/nginx.v2ray-websocket-param.template && \
    curl -L https://github.com/techotaku/patriot/raw/master/docker/template/haproxy.cfg.template -o /etc/mo/template/haproxy.cfg.template && \
    curl -L https://github.com/techotaku/patriot/raw/master/docker/template/mudb.json.template -o /etc/mo/template/mudb.json.template && \
    curl -L https://github.com/techotaku/patriot/raw/master/docker/template/ocserv.conf.template -o /etc/mo/template/ocserv.conf.template && \
    curl -L https://github.com/techotaku/patriot/raw/master/docker/template/supervisord.conf.template -o /etc/mo/template/supervisord.conf.template && \
    curl -L https://github.com/techotaku/patriot/raw/master/docker/template/userapiconfig.py.template -o /etc/mo/template/userapiconfig.py.template && \
    curl -L https://github.com/techotaku/patriot/raw/master/docker/template/user-config.json.template -o /etc/mo/template/user-config.json.template && \
    curl -L https://github.com/techotaku/patriot/raw/master/docker/template/usermysql.json.template -o /etc/mo/template/usermysql.json.template && \
    curl https://get.acme.sh | sh && crontab -l | sed 's#> /dev/null##' | crontab -

ENTRYPOINT ["entrypoint.sh"]