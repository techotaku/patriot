FROM alpine:3.6

MAINTAINER Ian Li <OpenSource@ianli.xyz>

ARG V2RAY_VER=2.34
ARG OC_VERSION=0.11.8

RUN apk add --no-cache bash curl nano ca-certificates python py-pip && \
    apk add --no-cache --virtual .ocserv-runtime-dependencies iptables musl openssl gnutls readline libnl3 lz4 lz4-libs libseccomp libev geoip && \
    apk add --no-cache --virtual .ocserv-build-dependencies build-base unzip xz linux-headers musl-dev gnutls-dev readline-dev libnl3-dev lz4-dev libseccomp-dev libev-dev geoip-dev && \
    pip install supervisor && \
    curl -O https://raw.githubusercontent.com/tests-always-included/mo/master/mo && \
    mv mo /usr/local/bin && \
    chmod +x /usr/local/bin/mo && \
    curl -L "https://github.com/v2ray/v2ray-core/releases/download/v${V2RAY_VER}/v2ray-linux-64.zip" -o /tmp/v2ray.zip && \
    unzip /tmp/v2ray.zip -d /tmp/ && \
    mv /tmp/v2ray-v${V2RAY_VER}-linux-64/v2ray /usr/local/bin/v2ray && \
    chmod +x /usr/local/bin/v2ray && \
    rm -rf /tmp/v2ray* && \
    curl -L "https://github.com/shadowsocksrr/shadowsocksr/archive/manyuser.zip" -o /tmp/shadowsocksr.zip && \
    unzip /tmp/shadowsocksr.zip -d /tmp/ && \
    mv /tmp/shadowsocksr-manyuser /opt/ && \
    rm /tmp/shadowsocksr.zip && \
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
    apk del .ocserv-build-dependencies