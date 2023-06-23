# syntax=docker/dockerfile:1
ARG FROM_IMAGE_JDK=azul/zulu-openjdk-alpine:11
ARG FROM_IMAGE=alpine:3.17
#ARG FROM_IMAGE=ubuntu:jammy
#ARG FROM_IMAGE=debian:bullseye-slim
FROM $FROM_IMAGE_JDK AS JDK

ARG FROM_IMAGE_JDK_PKGS_INSTALL="binutils wget"
ARG FROM_IMAGE_JDK_JAVA_VERSION="11"
ARG STACK_PROFILER_INSTALL=false
ARG ASYNC_PROFILER_INSTALL=true
ARG ASYNC_PROFILER_VERSION="2.5.1"
ARG TARGETARCH

RUN <<EOF
#!/usr/bin/env sh
set -e
set -x

PKG_CMD=$(which apk 2>/dev/null || which apt-get 2>/dev/null || type dnf 2>/dev/null | grep -v 'not found' | awk '{print $1}')
PKG_CMD=$(basename $PKG_CMD)
if [ -z "$PKG_CMD" ]; then
    echo "$FROM_IMAGE_JDK is not a supported container image.  Exiting..."
    exit 1
fi

JLINK=$(which jlink 2>/dev/null || type jlink 2>/dev/null | grep -v 'not found' | awk '{print $1}')
if [ -n "$JLINK" ]; then
    echo "$FROM_IMAGE_JDK appears to include a JDK."
    echo "Skipping JDK installation..."
else
    if [ "$PKG_CMD" = "apk" ]; then
        FROM_IMAGE_JDK_PKGS_INSTALL="$FROM_IMAGE_JDK_PKGS_INSTALL openjdk${FROM_IMAGE_JDK_JAVA_VERSION}"
    elif [ "$PKG_CMD" = "apt-get" ]; then
        FROM_IMAGE_JDK_PKGS_INSTALL="$FROM_IMAGE_JDK_PKGS_INSTALL openjdk-${FROM_IMAGE_JDK_JAVA_VERSION}-jdk-headless"
    elif [ "$PKG_CMD" = "dnf" ]; then
        FROM_IMAGE_JDK_PKGS_INSTALL="$FROM_IMAGE_JDK_PKGS_INSTALL java-${FROM_IMAGE_JDK_JAVA_VERSION}-openjdk-devel java-${FROM_IMAGE_JDK_JAVA_VERSION}-openjdk-jmods"
    else
        echo "Error. Exiting..."
        exit 1
    fi
fi

if [ "$PKG_CMD" = "apk" ]; then
    apk add --no-cache $FROM_IMAGE_JDK_PKGS_INSTALL
elif [ "$PKG_CMD" = "apt-get" ]; then
    apt-get update
    apt-get install -y $FROM_IMAGE_JDK_PKGS_INSTALL
elif [ "$PKG_CMD" = "dnf" ]; then
    dnf install -y $FROM_IMAGE_JDK_PKGS_INSTALL
else
    echo "Error. Exiting..."
    exit 1
fi

JLINK=$(which jlink 2>/dev/null || type jlink 2>/dev/null | awk '{print $1}')
$JLINK --compress=2 \
      --no-header-files \
      --no-man-pages \
      --strip-debug \
      --add-modules java.base,java.compiler,java.desktop,java.instrument,java.management.rmi,java.prefs,java.security.jgss,\
java.security.sasl,java.sql,jdk.security.auth,jdk.unsupported,java.datatransfer,java.logging,java.naming,java.rmi,java.scripting,\
java.sql.rowset,java.transaction.xa,java.xml,java.xml.crypto,jdk.xml.dom,\
jdk.crypto.ec,jdk.crypto.cryptoki,jdk.jfr,jdk.jcmd,jdk.jdwp.agent,jdk.naming.dns,jdk.zipfs,jdk.management.agent \
      --output /opt/jdk
cp $(type jstack | awk '{print $NF}') /opt/jdk/bin
cp $(type jps | awk '{print $NF}') /opt/jdk/bin
strip -p --strip-unneeded /opt/jdk/lib/server/libjvm.so

# Installs the GCP stack driver profiler - adds ~8MB
if [ "$STACK_PROFILER_INSTALL" = "true" ]; then
    mkdir -p /opt/cprof
    STACK_PROFILER_URL="https://storage.googleapis.com/cloud-profiler/java/latest/profiler_java_agent.tar.gz"
    wget -q -O- $STACK_PROFILER_URL | tar xzv -C /opt/cprof
    chmod 0555 /opt/cprof/*.so
else
    echo "Skipping stack driver profiler installation..."
fi

# Installs the async-profiler - adds 280K
if [ "$ASYNC_PROFILER_INSTALL" = "true" ]; then
    mkdir -p /opt/async-profiler
    ASYNC_PROFILER_ARCH=$TARGETARCH
    [ "$ASYNC_PROFILER_ARCH" = "amd64" ] && ASYNC_PROFILER_ARCH=x64
    ASYNC_PROFILER_URL="https://github.com/jvm-profiling-tools/async-profiler/releases/download/v${ASYNC_PROFILER_VERSION}/async-profiler-${ASYNC_PROFILER_VERSION}-linux-${ASYNC_PROFILER_ARCH}.tar.gz"
    wget -q -O- $ASYNC_PROFILER_URL | tar xzv -C /opt/async-profiler
else
    echo "Skipping async-profiler installation..."
fi
EOF

# Product image
FROM $FROM_IMAGE

ARG FROM_IMAGE_UPGRADE=false
ARG FROM_IMAGE_PKGS_INSTALL="ca-certificates procps"

COPY --from=JDK /opt /opt
RUN <<EOF
#!/usr/bin/env sh
set -e
set -x

PKG_CMD=$(which apk 2>/dev/null || which apt-get 2>/dev/null || type dnf 2>/dev/null | awk '{print $1}')
PKG_CMD=$(basename $PKG_CMD)
if [ -z "$PKG_CMD" ]; then
    echo "$FROM_IMAGE_JDK is not a supported container image.  Exiting..."
    exit 1
fi

if [ "$PKG_CMD" = "apk" ]; then
    [ "$FROM_IMAGE_UPGRADE" = "true" ] && apk upgrade
    apk add --no-cache $FROM_IMAGE_PKGS_INSTALL
elif [ "$PKG_CMD" = "apt-get" ]; then
    apt-get update
    [ "$FROM_IMAGE_UPGRADE" = "true" ] && apt-get upgrade -y
    apt-get install -y $FROM_IMAGE_PKGS_INSTALL
    apt-get clean
    rm -rf /var/lib/apt/lists/*
elif [ "$PKG_CMD" = "dnf" ]; then
    [ "$FROM_IMAGE_UPGRADE" = "true" ] && dnf upgrade -y
    dnf install -y $FROM_IMAGE_PKGS_INSTALL
    dnf clean all
else
    echo "Error. Exiting..."
    exit 1
fi

USER="forgerock"
HOME="/home/$USER"
GECOS="$USER user"
if [ "$PKG_CMD" = "apk" ]; then
    adduser -h $HOME -u 11111 -G root \
        -D -g "$GECOS" $USER
elif [ "$PKG_CMD" = "apt-get" ]; then
    adduser --home $HOME -uid 11111 --gid 0 \
        --disabled-password --gecos "$GECOS" $USER
elif [ "$PKG_CMD" = "dnf" ]; then
    adduser --home-dir $HOME --uid 11111 --gid 0 \
        --system --comment "$GECOS" $USER
else
    echo "Error. Exiting..."
    exit 1
fi
EOF

ENV JAVA_HOME /opt/jdk
ENV PATH $PATH:/opt/jdk/bin
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
#ENV TZ=Etc/UTC

