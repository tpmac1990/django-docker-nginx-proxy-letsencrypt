FROM nginx:1.23.0-alpine

# the /etc/nginx/ directory exists in the nginx image, so here we want to copy our contents into the existing /etc/nginx/ and overwrite the matching files with our own. This is why we use 'COPY ./nginx/* /etc/nginx/' instead of 'COPY ./nginx /etc/nginx'.
COPY ./nginx/* /etc/nginx/
COPY ./run.sh /run.sh

# The container the django app is run inside, from the Dockerfile
ENV APP_HOST=app
# This is the port the django app is running on
ENV APP_PORT=9000

USER root

# add requirements to run the script
RUN apk add --no-cache openssl bash
# make sure the run script is executable
RUN chmod +x /run.sh

# specify the two volumes
# static files
VOLUME /vol/static
# used to server the cerbot challenge from the cerbot volume
VOLUME /vol/www

# default command to run run.sh script
CMD ["/run.sh"]
