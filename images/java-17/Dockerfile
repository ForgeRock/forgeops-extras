# Base Java Image for ForgeRock Identity Platform. Used for DS, amster, IGx and IDM (Anything that does not need a web
# container)
#
# Copyright 2019-2023 ForgeRock AS. All Rights Reserved
#
# Use of this code requires a commercial software license with ForgeRock AS.
# or with one of its affiliates. All use shall be exclusively subject
# to such license between the licensee and ForgeRock AS.
#
FROM azul/zulu-openjdk-debian:17 AS JDK
RUN   apt-get update && apt-get install -y binutils wget \
      && jlink --compress=2 \
          --no-header-files \
          --no-man-pages \
          --strip-debug \
          --add-modules java.base,java.compiler,java.desktop,java.instrument,java.management.rmi,java.prefs,java.security.jgss,\
java.security.sasl,java.sql,jdk.security.auth,jdk.unsupported,java.datatransfer,java.logging,java.naming,java.rmi,java.scripting,\
java.sql.rowset,java.transaction.xa,java.xml,java.xml.crypto,jdk.xml.dom,\
jdk.crypto.ec,jdk.crypto.cryptoki,jdk.jfr,jdk.jcmd,jdk.jdwp.agent,jdk.naming.dns,jdk.zipfs,jdk.management.agent \
          --output /opt/jdk \
   && cp /usr/lib/jvm/zulu17/bin/jstack /opt/jdk/bin \
   && cp /usr/lib/jvm/zulu17/bin/jps /opt/jdk/bin \
   && strip -p --strip-unneeded /opt/jdk/lib/server/libjvm.so

# This installs the GCP stack driver profiler. Adds approx 8MB
# RUN mkdir -p /opt/cprof && \
#      wget -q -O- https://storage.googleapis.com/cloud-profiler/java/latest/profiler_java_agent.tar.gz \
#      | tar xzv -C /opt/cprof && \
#      chmod 0555 /opt/cprof/*.so

# Installs the async-profiler - adds 280K
# This has not been tested on ARM based systems - see CLOUD-1448
RUN mkdir -p /opt/async-profiler && \
    wget -q -O-  https://github.com/jvm-profiling-tools/async-profiler/releases/download/v2.5/async-profiler-2.5-linux-x64.tar.gz \
    | tar xzv -C /opt/async-profiler


FROM debian:bullseye-slim

COPY --from=JDK /opt /opt
COPY Dockerfile /Dockerfile.java-17

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
