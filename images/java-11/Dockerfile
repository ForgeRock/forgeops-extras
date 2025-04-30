# Base Java Image for ForgeRock Identity Platform. Used for DS, amster, IG and IDM (Anything that does not need a web
# container)
#
# Copyright 2019-2024 Ping Identity Corporation. All Rights Reserved
#
# This code is to be used exclusively in connection with Ping Identity
# Corporation software or services. Ping Identity Corporation only offers
# such software or services to legal entities who have entered into a
# binding license agreement with Ping Identity Corporation.
#
FROM azul/zulu-openjdk-debian:11-latest
RUN jlink --compress=2 \
          --no-header-files \
          --no-man-pages \
          --strip-debug \
          --add-modules ALL-MODULE-PATH \
          --output /opt/jdk \
   && cp /usr/bin/jstack /opt/jdk/bin \
   && cp /usr/bin/jps /opt/jdk/bin \
   && apt-get update && apt-get install -y binutils wget \
   && strip -p --strip-unneeded /opt/jdk/lib/server/libjvm.so

# This installs the GCP stack driver profiler. Adds approx 8MB
RUN mkdir -p /opt/cprof && \
     wget -q -O- https://storage.googleapis.com/cloud-profiler/java/latest/profiler_java_agent.tar.gz \
     | tar xzv -C /opt/cprof && \
     chmod 0555 /opt/cprof/*.so

# Installs the async-profiler - adds 280K
# This has not been tested on ARM based systems - see CLOUD-1448
RUN mkdir -p /opt/async-profiler && \
    wget -q -O-  https://github.com/jvm-profiling-tools/async-profiler/releases/download/v1.5/async-profiler-1.5-linux-x64.tar.gz \
    | tar xzv -C /opt/async-profiler


FROM debian:buster-slim
# TODO: Upgrade to bullseye when pipeline is stable
# FROM debian:bullseye-slim

COPY --from=0 /opt /opt
COPY Dockerfile /Dockerfile.java-11

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