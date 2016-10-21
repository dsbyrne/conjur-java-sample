#!/usr/bin/env bash
set -eo pipefail

# Arguments
account="$1"
hostname="$2"
identity="$3"
api_key="$4"

appliance_url="https://$hostname/api"
cert_path="/etc/conjur-$account.pem"
certificate="`echo | openssl s_client -connect $hostname:443 -showcerts 2>/dev/null | sed -n -e '/BEGIN\ CERTIFICATE/,/END\ CERTIFICATE/ p'`"

# Implementation note: 'tee' is used as a sudo-friendly 'cat' to populate a file with the contents provided below.

# Create /etc/conjur.conf, which references the other two files
tee /etc/conjur.conf > /dev/null << EOF
account: $account
appliance_url: $appliance_url
cert_file: $cert_path
netrc_path: /etc/conjur.identity
EOF

# Create /etc/conjur-account.pem for certificate validation
echo "$certificate" > $cert_path

# Create netrc file containing our identity information
touch /etc/conjur.identity
chmod 600 /etc/conjur.identity
tee /etc/conjur.identity > /dev/null << EOF
machine $appliance_url/authn
        login host/$identity
        password $api_key
EOF