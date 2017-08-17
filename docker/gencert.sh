#!/bin/sh
set -e

ROOT="$1"
ORG="$2"
DOMAIN="$3"
USERNAME="$4"
PASSWORD="$5"
CLIENT="${USERNAME}@${DOMAIN}"

mkdir -p "${ROOT}"
cd "${ROOT}"

cat > ca.tmpl <<_EOF_
cn = "${ORG} Root CA"
organization = "${ORG}"
serial = 1
expiration_days = 3650
ca
signing_key
cert_signing_key
crl_signing_key
_EOF_

cat > server.tmpl <<_EOF_
cn = "${DOMAIN}"
dns_name = "${DOMAIN}"
organization = "${ORG}"
serial = 2
expiration_days = 3650
encryption_key
signing_key
tls_www_server
_EOF_

cat > client.tmpl <<_EOF_
cn = "${CLIENT}"
uid = "${CLIENT}"
unit = "${ORG}"
expiration_days = 3650
signing_key
tls_www_client
_EOF_

if [ ! -f "ca.key.pem" ]; then
    echo "[Info] Generating Root CA..."
    certtool --generate-privkey --outfile ca.key.pem
    certtool --generate-self-signed --load-privkey ca.key.pem --template ca.tmpl --outfile ca.crt.pem
fi

if [ ! -f "${DOMAIN}".crt.pem ]; then
    echo "[Info] Generating server cert for ${DOMAIN}..."
    certtool --generate-privkey --outfile "${DOMAIN}".key.pem
    certtool --generate-certificate --load-privkey "${DOMAIN}".key.pem --load-ca-certificate ca.crt.pem --load-ca-privkey ca.key.pem --template server.tmpl --outfile "${DOMAIN}".crt.pem
fi

if [ ! -z "$USERNAME" ] && [ ! -z "$PASSWORD" ] && [ ! -f "${CLIENT}".p12 ]; then
    echo "[Info] Generating client cert for ${CLIENT}..."
    certtool --generate-privkey --outfile "${CLIENT}".key.pem
    certtool --generate-certificate --load-privkey "${CLIENT}".key.pem --load-ca-certificate ca.crt.pem --load-ca-privkey ca.key.pem --template client.tmpl --outfile "${CLIENT}".crt.pem
    certtool --to-p12 --pkcs-cipher 3des-pkcs12 --load-ca-certificate ca.crt.pem --load-certificate "${CLIENT}".crt.pem --load-privkey "${CLIENT}".key.pem --outfile "${CLIENT}".p12 --outder --p12-name "${DOMAIN}" --password "${PASSWORD}"
fi

rm ca.tmpl
rm server.tmpl
rm client.tmpl

cd $OLDPWD