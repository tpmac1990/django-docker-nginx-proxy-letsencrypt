#!/bin/sh

# Waits for proxy to be available, then gets the first certificate.

# this is a script used to certify the first time we run our service

set -e

# first we need to wait for the proxy to be available. In docker-compose you can specify that one service depends on another, which means it will wait for one service to start before the other starts, however it doesn't garantee that the application running in that service has had time to start, it only garantees the service itself has started. e.g. garanteeing you have turned on the computer but not garanteeing the browser has loaded. This ensures the nginx server is up and running and it has done everything like generating the dhparams and things like that that takes some time the first time, so we need to wait until that happens. The way we do that is with this netcat command and netcat just checks to see whether a tcp port is accessible in the provided container (proxy container in docker-compose-deploy.yml)
until nc -z proxy 80; do
    echo "Waiting for proxy..."
    sleep 5s & wait ${!}
done

echo "Getting certificate..."

# certbot is designed to do all the configuration for you on nginx, we're not doing that because we are running it in docker and I want it to be reproduceable and I want to run it as a docker service alongside our existing services. To do that, we need to provide the certonly flag to the command. certonly tells certbot that we don't want it to actually setup out nginx service for us because that wouldn't work because we are not running it straight on a server, we're running it in a separate docker service. We just want it to generate a certificate for us and then we'll do the configuration of that certificate ourselves which we have done through volumes and nginx configuration.
certbot certonly \
    # use --webroot method of authentication
    --webroot \
    # the webroot of our server we will use to server the authentication challenge is at /vol/www/ and that is where it will put the challenge.
    --webroot-path "/vol/www/" \
    # a certificate needs to be created for a specific domain
    -d "$DOMAIN" \
    # need to provide a valid email
    --email $EMAIL \
    # 4096 is the recommended key size
    --rsa-key-size 4096 \
    # agree to certbots terms of serice
    --agree-tos \
    # we are not doing this process manually, so we can't enter any inputs when we deploy the application.
    --noninteractive
