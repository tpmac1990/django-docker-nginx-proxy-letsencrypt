#!/bin/bash

set -e

# generates a 2048-bit Diffie-Hellman parameter file and saves it to the specified 
# location (/vol/proxy/ssl-dhparams.pem). This file is often used in SSL/TLS 
# configurations to enable perfect forward secrecy, a feature that enhances security 
# by ensuring that even if an attacker obtains the private key, they cannot decrypt 
# past SSL/TLS communications.
echo "Checking for dhparams.pem"
if [ ! -f "/vol/proxy/ssl-dhparams.pem" ]; then
  echo "dhparams.pem does not exist - creating it"
  # this '/vol/proxy/ssl-dhparams.pem' should match the ssl_dhparam location in 
  # defaul-ssl.config.tpl file.
  openssl dhparam -out /vol/proxy/ssl-dhparams.pem 2048
fi

# NOTE: the below three lines were not included in the video
# # avoid replacing these with envsubst
# export host=\$host
# export request_uri=\$request_uri

# sets the .tpl file to run depending on whether fullchain.pem exists
echo "Checking for fullchain.pem"
if [ ! -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]; then
  # run first time to get the certificate
  echo "No SSL cert, enabling HTTP only..."
  # this inserts the environment variables in to the default.conf.tpl file and then
  #  saves it as default.conf in the conf.d directory.
  envsubst < /etc/nginx/default.conf.tpl > /etc/nginx/conf.d/default.conf
else
  # run most of the time
  echo "SSL cert exists, enabling HTTPS..."
  envsubst < /etc/nginx/default-ssl.conf.tpl > /etc/nginx/conf.d/default.conf
fi

# starts the nginx server and runs it in the forground
nginx-debug -g 'daemon off;'
