# Base Java Image for ForgeRock Identity Platform. Used for DS, amster, IG and IDM (Anything that does not need a web
# container)
#
# Copyright 2025 Ping Identity Corporation. All Rights Reserved
#
# This code is to be used exclusively in connection with Ping Identity
# Corporation software or services. Ping Identity Corporation only offers
# such software or services to legal entities who have entered into a
# binding license agreement with Ping Identity Corporation.
#
FROM azul/zulu-openjdk-debian:25 AS JDK
RUN   apt-get update && apt-get install -y binutils \
   && jlink \
      --no-header-files \
      --no-man-pages \
      --strip-debug \
      --add-modules ALL-MODULE-PATH \
      --module-path /usr/lib/jvm/zulu25/jmods \
      --output /opt/jdk \
   && strip -p --strip-unneeded /opt/jdk/lib/server/libjvm.so

FROM debian:bookworm-slim

RUN mkdir /opt/jdk

COPY --from=JDK /opt/jdk /opt/jdk
COPY Dockerfile /Dockerfile.java-25

# Add in ca-certificates needed for uploads to google cloud storage.
RUN adduser --home "/home/forgerock" -uid 11111 --gid 0 forgerock --disabled-password --gecos "forgerock user" && \
   apt-get update && \
   apt-get -y upgrade && \
   apt-get install -y ca-certificates procps && \
   rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /opt/jdk

ENV PATH $PATH:/opt/jdk/bin

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
