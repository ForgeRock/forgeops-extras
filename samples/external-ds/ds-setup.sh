#!/usr/bin/env bash
#
# Pre-setup for DS. This runs at docker build time. It creates a skeleton DS instance
# that is ready for futher customization with the runtime 'setup' script.
# After completion, a tar file is created with the contents of the setup. This tar file
# is kept as part of the docker images, and expanded at setup time to "prime" the PVC
# with the ds instance.
#
# The contents of this file are subject to the terms of the Common Development and
# Distribution License (the License). You may not use this file except in compliance with the
# License.
#
# You can obtain a copy of the License at legal/CDDLv1.0.txt. See the License for the
# specific language governing permission and limitations under the License.
#
# When distributing Covered Software, include this CDDL Header Notice in each file and include
# the License file at legal/CDDLv1.0.txt. If applicable, add the following below the CDDL
# Header, with the fields enclosed by brackets [] replaced by your own identifying
# information: "Portions Copyright [year] [name of copyright owner]".
#
# Copyright 2019-2024 Ping Identity Corporation
#
set -eux

deploymentId=`./bin/dskeymgr create-deployment-id --deploymentIdPassword password`

./setup --instancePath $DS_DATA_DIR \
        --serverId                docker \
        --hostname                localhost \
        --deploymentId            ${deploymentId} \
        --deploymentIdPassword    password \
        --rootUserPassword        password \
        --adminConnectorPort      4444 \
        --ldapPort                1389 \
        --enableStartTls \
        --ldapsPort               1636 \
        --httpPort                8080 \
        --httpsPort               8443 \
        --replicationPort         8989 \
        --rootUserDn              uid=admin \
        --monitorUserDn           uid=monitor \
        --monitorUserPassword     password \
        --acceptLicense

# These relax some settings needed by the current forgeops deployment.
dsconfig --offline --no-prompt --batch <<END_OF_COMMAND_INPUT
set-global-configuration-prop --set "unauthenticated-requests-policy:allow"

set-password-policy-prop --policy-name "Default Password Policy" \
                         --set "require-secure-authentication:false" \
                         --set "require-secure-password-changes:false" \
                         --reset "password-validator"

set-password-policy-prop --policy-name "Root Password Policy" \
                         --set "require-secure-authentication:false" \
                         --set "require-secure-password-changes:false" \
                         --reset "password-validator"
END_OF_COMMAND_INPUT


### Setup the PEM trustore. This is REQUIRED. ######

# Set up a PEM Trust Manager Provider
dsconfig --offline --no-prompt --batch <<EOF
create-trust-manager-provider \
            --provider-name "PEM Trust Manager" \
            --type pem \
            --set enabled:true \
            --set pem-directory:${PEM_TRUSTSTORE_DIRECTORY}

set-connection-handler-prop \
            --handler-name https \
            --set trust-manager-provider:"PEM Trust Manager"
set-connection-handler-prop \
            --handler-name ldap \
            --set trust-manager-provider:"PEM Trust Manager"
set-connection-handler-prop \
            --handler-name ldaps \
            --set trust-manager-provider:"PEM Trust Manager"
set-synchronization-provider-prop \
            --provider-name "Multimaster Synchronization" \
            --set trust-manager-provider:"PEM Trust Manager"
set-administration-connector-prop \
            --set trust-manager-provider:"PEM Trust Manager"

# Delete the default PCKS12 provider.
delete-trust-manager-provider \
            --provider-name "PKCS12"


# Set up a PEM Key Manager Provider
create-key-manager-provider \
            --provider-name "PEM Key Manager" \
            --type pem \
            --set enabled:true \
            --set pem-directory:${PEM_KEYS_DIRECTORY}

set-connection-handler-prop \
            --handler-name https \
            --set key-manager-provider:"PEM Key Manager"
set-connection-handler-prop \
            --handler-name ldap \
            --set key-manager-provider:"PEM Key Manager"
set-connection-handler-prop \
            --handler-name ldaps \
            --set key-manager-provider:"PEM Key Manager"
set-synchronization-provider-prop \
            --provider-name "Multimaster Synchronization" \
            --set key-manager-provider:"PEM Key Manager"
set-crypto-manager-prop \
            --set key-manager-provider:"PEM Key Manager"
set-administration-connector-prop \
            --set key-manager-provider:"PEM Key Manager"

# Delete the default PCKS12 provider.
delete-key-manager-provider \
            --provider-name "PKCS12"
EOF

# The profiles are read only - make them writable
chmod -R a+rw  template/setup-profiles/AM
chmod -R a+rw  template/setup-profiles/IDM

# Add custom ldap entries to the am-config base entries
cat ldif-ext/am-config/uma/*.ldif ldif-ext/am-config/*.ldif >> template/setup-profiles/AM/config/6.5/base-entries.ldif

# Add custom ldap entries to the identity-store base entries
if [ -f ldif-ext/identities/*.ldif ]; then
    cat ldif-ext/identities/*.ldif >> template/setup-profiles/AM/identity-store/7.0/base-entries.ldif
fi

# Add custom ldap entries to the tokens base entries
if [ -f ldif-ext/tokens/*.ldif ]; then
    cat ldif-ext/tokens/*.ldif >> template/setup-profiles/AM/cts/6.5/base-entries.ldif
fi

# Add custom ldap entries to the idm-repo base entries
if [ -f ldif-ext/idm-repo/*.ldif ]; then
    cat ldif-ext/idm-repo/*.ldif >> template/setup-profiles/IDM/repo/7.3/base-entries.ldif
fi
