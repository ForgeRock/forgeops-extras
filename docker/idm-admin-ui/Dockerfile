ARG REPO=nginx
ARG TAG=1.31.5-alpine

FROM ${REPO}:${TAG}
ARG VERSION=8.1.1

RUN apk -U upgrade && \
    apk add unzip

COPY src/${VERSION}.zip /tmp
COPY nginx.conf /etc/nginx/nginx.conf

RUN unzip /tmp/${VERSION}.zip -d /tmp && \
    rm -rf /usr/share/nginx/html/* && \
    cp -rp /tmp/PingIDM-Legacy-Admin-UI/www/* /usr/share/nginx/html

RUN apk del unzip
