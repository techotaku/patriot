# Docker    

## Usage     

```
sudo docker run -d --name patriot \
    -v $HOME/patriot:/etc/patriot \
    -p 443:443 -p 80:80 \
    -e "SSL_DOMAIN=example.test" \
    -e "V2RAY_HTTP_WEBSOCKET_PATH=api" \
    -e "ACME_EMAIL=admin@example.test" \
    --cap-add=NET_ADMIN \
    --log-opt max-size=1m \
    --restart=unless-stopped \
    tarot13/patriot
```

Put your CA certificate for OCserv to `$HOME/patriot/ssl/ocserv.ca.pem`, or a self-signed CA certificate will be generated to `$HOME/patriot/ca/ca.crt.pem`.    

If you want generate client certificate with this self-signed CA certificate, get into container then `gencert.sh "/etc/patriot/ca" "Patriot" "example.test" "name" "certificate_password"`.    