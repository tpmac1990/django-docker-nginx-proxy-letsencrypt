# offical image for certbot
FROM certbot/certbot:v1.27.0

# copy over the script
COPY certify-init.sh /opt/
# make it executable
RUN chmod +x /opt/certify-init.sh

# override the entrypoint
ENTRYPOINT []
# the default is to renew as this is what it will be used for after the initial deployment in which case it will be to generate.
CMD ["certbot", "renew"]
