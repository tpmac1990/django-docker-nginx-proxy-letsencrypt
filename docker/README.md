
## How the proxy works
- The Django application is hosted within the app service, operating on port 9000. This service is responsible for serving the application's content.
- The proxy service operates on ports 80 and 443, handling incoming web traffic. It redirects incoming requests to the app service running on port 9000.
- Before redirecting, the proxy orchestrates the SSL/TLS certificate issuance process. The certificate authority, typically Certbot, issues a challenge that the proxy must successfully navigate to prove domain ownership and obtain SSL certificates.
- The proxy project also enforces an HTTP-to-HTTPS redirect, ensuring that all incoming HTTP requests are automatically redirected to the secure HTTPS protocol for improved security and data encryption.


## Dockerfiles
There are 3 Dockerfiles in the project
Dockerfile: Runs the django application
docker/proxy/Dockerfile: Runs nginx
docker/certbot/Dockerfile: Runs the certbot


## .tpl extension file
These aren't the finished configuration files. These are template configuration files that are used to generate the configuration files based on environment variables that we pass to out app. This will allow us to do things like override the domain name and customize it for our own domain name without having to hardcode it in the project. It is `proxy/run.sh`


## proxy/nginx/default.conf.tpl
This is the configuration file that serves out web server just on plain http. So this is what is needed when we first start out app and we haven't yet created out certificates. The reason we need to use this is because we need to be able to handle a challenge file that is sent by certbot. certbot provides a challenge and we need to be able to serve that challenge via plain http in order to initialize our first certificates.
This is a simple nginx config:
${}: environment variables set in the container
```
    server {
        listen 80;
        server_name ${DOMAIN} www.${DOMAIN};

        # the location let's encrypt expects to find the challenge file to complete 
        #  authentication.
        location /.well-known/acme-challenge/ {
            # this is a volume set in the docker-compose file that can be shared with
            #  certbot. The file can be placed there and nginx can access the file
            root /vol/www/;
        }

        # Everything that does not match .well-known/acme-challenge/ we want to forward to
        #  https. This is the recommended way to forward http to https using nginx.
        location / {
            return 301 https://$host$request_uri;
        }
    }
```


## proxy/nginx/default-ssl.conf.tpl
Used when we do have a certificate (above is used when we don't have a certificate).
The reason we need two separate files is if you have the https configuration in the above file (default.conf.tpl) then nginx will crash because the certificates that it needs to server https will not be accessible. That is why we need to create two separate files for this
The first part is the same as in default.conf.tpl. This is because we will either run this file or the other, so we still want to serve http without the s for the acme challenge, and we still want to handle the https redirect.
The second server block  
```
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};

    location /.well-known/acme-challenge/ {
        root /vol/www/;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    # listen on port 443 (https default) and enable ssl
    listen      443 ssl;
    server_name ${DOMAIN} www.${DOMAIN};

    # this is a basic certificate & certificate key required in order to server https on 
    #  any web server.
    ssl_certificate     /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    # the volume the certificates are mapped to from certbot which are then accessible by 
    #  nginx.
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;

    # configuration file from the certbot github page which includes the basic
    #  configuration that is required for an nginx server. The basic configuration needed
    #  to server a cert or generated certificate using nginx.
    include     /etc/nginx/options-ssl-nginx.conf;

    # These are the diffie-hellman params used to strengthen the encryption.
    ssl_dhparam /vol/proxy/ssl-dhparams.pem;

    # adds a http header to the requests that tells the browser to remember that this web
    #  domain should be accessed via https
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Serve static files from this directory.
    location /static {
        alias /vol/static;
    }

    # if we haven't matched any of the previous location blocks then forward the request
    #  using uwsgi to the django application.
    # ${APP_HOST}:${APP_PORT} = app:9000
    # app is the name of the service containing the Django app in the Dockerfile
    # 9000 is the port the django app is run on.
    # Here uwsgi_pass is used as we are redirecting to the application server, we could also use proxy_pass, but then it would be something like http://${APP_HOST}:${APP_PORT}
    location / {
        uwsgi_pass           ${APP_HOST}:${APP_PORT}; 
        include              /etc/nginx/uwsgi_params; # config file provided by uwsgi docs
        client_max_body_size 10M;
    }
}
```


## proxy/nginx/options-ssl-nginx.conf
get from: https://github.com/certbot/certbot/blob/1.28.0/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf
Use the same version.
SSL (Secure Sockets Layer) configuration settings for NGINX, which are typically included in an NGINX server block to configure how NGINX handles secure connections using HTTPS.
Used to enable SSL (Secure Sockets Layer) or TLS (Transport Layer Security) encryption. SSL/TLS encryption is used to secure the communication between a web server and a client, ensuring that data transmitted between them is encrypted and protected from eavesdropping or tampering.
```
ssl_session_cache shared:le_nginx_SSL:10m;
ssl_session_timeout 1440m;
ssl_session_tickets off;

ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers off;

ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
```


## nginx/uwsgi_params
get from here: https://uwsgi-docs.readthedocs.io/en/latest/Nginx.html
The file contains a set of predefined variables and configurations that are used to interface Nginx (or other web servers) with the uWSGI application server. These parameters help in forwarding client requests from the web server to the uWSGI server and managing the communication between them.
```
uwsgi_param QUERY_STRING $query_string;
uwsgi_param REQUEST_METHOD $request_method;
uwsgi_param CONTENT_TYPE $content_type;
uwsgi_param CONTENT_LENGTH $content_length;
uwsgi_param REQUEST_URI $request_uri;
uwsgi_param PATH_INFO $document_uri;
uwsgi_param DOCUMENT_ROOT $document_root;
uwsgi_param SERVER_PROTOCOL $server_protocol;
uwsgi_param REMOTE_ADDR $remote_addr;
uwsgi_param REMOTE_PORT $remote_port;
uwsgi_param SERVER_ADDR $server_addr;
uwsgi_param SERVER_PORT $server_port;
uwsgi_param SERVER_NAME $server_name;
```


## docker/certbot/certify-init.sh
This is a script that we use to certify the first time we run.
Notes are in the file.