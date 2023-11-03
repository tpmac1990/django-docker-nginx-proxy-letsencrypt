FROM python:3.10-alpine3.16

# prints all of the outputs that come from our python application
ENV PYTHONUNBUFFERED 1

COPY requirements.txt /requirements.txt

# --no-cache: don't store cache in docker image to keep it as light as possible
RUN apk add --upgrade --no-cache build-base linux-headers && \
    pip install --upgrade pip && \
    pip install -r /requirements.txt

COPY app/ /app
WORKDIR /app

# create a user to run the application as we don't want to run it in root user mode
RUN adduser --disabled-password --no-create-home django

USER django

# uwsgi: used to run the service
# run on port 9000
# 4 worker threads on the application
# --master: run it in the foreground so we get all the logs and outputs from the application directly
# --enable-threads: incase you want to have multiple threads in the django app
# set the module to app.wsgi which is something that is auto created by django in a moment
CMD ["uwsgi", "--socket", ":9000", "--workers", "4", "--master", "--enable-threads", "--module", "app.wsgi"]
