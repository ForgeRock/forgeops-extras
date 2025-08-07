#!/usr/bin/env bash
#

unzip /opt/DS-7.5.1.zip

echo "Copying required files from forgeops"
cp -r forgeops/docker/ds/ds-new/ldif-ext /opt/opendj
cp -r forgeops/docker/ds/ds-new/default-scripts /opt/opendj/default-scripts
cp -r ds-setup.sh /opt/opendj

echo "Adding opendj/bin to you path"
export PATH=${PATH}:/opt/opendj/bin

echo "Create keystore provider folders"
mkdir -p /opt/opendj/truststore /opt/opendj/keystore

echo "Set env vars"
export DS_DATA_DIR=data
export PEM_TRUSTSTORE_DIRECTORY=/opt/opendj/truststore
export PEM_KEYS_DIRECTORY=/opt/opendj/keystore
