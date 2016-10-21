#!/usr/bin/env bash
set -eo pipefail

# Arguments
hostname="$1"
username="$2"
password="$3"

# If arguments are not present, we'll prompt the user to input them at runtime
if [[ -z $hostname ]]; then
  echo "What is the resolvable hostname of your Conjur master? (Ex: conjur.myorg.com)"
  read hostname
fi

appliance_url="https://$hostname/api"

# To make sure we have the correct information, we'll try an empty
# authorization request. We expect this to fail with a 401. Otherwise, it is 
# safe to assume our hostname is incorrect.
if [[ -z "`curl -kIs $appliance_url/authn/users/login | grep '401 Unauthorized'`" ]]; then
  echo "FATAL: Invalid hostname"
  exit 1
fi

if [[ -z $username ]]; then
  echo -e "\nWhat is your Conjur username?"
  read username
fi

if [[ -z $password ]]; then
  echo -e "\nWhat is your Conjur password? (Input will not be displayed)"
  read -s password
fi

# json_value
# Uses python to resolve a value from a JSON blob
json_value () {
  python -c "import json,sys;sys.stdout.write(json.load(sys.stdin)$1)"
}

# new_token
# Authenticates using username/password to retrieve a signed token. This token
# is used as the Authorization header in subsequent requests. It has an eight
# minute TTL, so we shouldn't need to worry about refreshing it in this script.
# http://docs.conjur.apiary.io/#reference/authentication/authenticate/exchange-a-user-login-and-api-key-for-an-access-token
new_token () {
  echo "`curl -X POST --data "$password" -ks $appliance_url/authn/users/$username/authenticate | base64`"
}
token="`new_token`"

# set_variable_value
# Sets the value of an existing variable. In our case, we'll use it to set the
# values of the variables loaded in the 'app' policy.
# http://docs.conjur.apiary.io/#reference/variable/values-add/add-a-value-to-a-variable
set_variable_value () {
  id="$1"
  value="$2"

  curl -X POST -ks \
    -H "Content-Type: application/json" \
    -H 'Authorization: Token token="'$token'"' \
    --data-binary '{"value": "'$value'"}' \
    $appliance_url/variables/$id/values
}

future_date="2050-01-01T00:00:00-05:00"
# create_host_factory_token
# Creates a token from the host factory created in the 'app' policy. This token
# can be used to generate new host roles in the 'app' layer. This layer is What
# has permission to read app variables.
# http://docs.conjur.apiary.io/#reference/host-factory/create-token/create-a-new-host-factory-token
create_host_factory_token () {
  host_factory="$1"

  curl -X POST -ks \
    -H 'Authorization: Token token="'$token'"' \
    $appliance_url/host_factories/$host_factory/tokens?expiration=$future_date | json_value "[0]['token']"
}

# create_host
# Exchanges the host factory token for a host identity
# http://docs.conjur.apiary.io/#reference/host-factory/create-host/create-a-new-host-using-a-host-factory-token
create_host () {
  host_factory_token="$1"
  host_id="$2"

  curl -X POST -ks \
    -H 'Authorization: Token token="'$host_factory_token'"' \
    $appliance_url/host_factories/hosts?id=$host_id | json_value "['api_key']"
}

# get_account
# Requests the account this Conjur server is configured to use
get_account () {
  curl -ks $appliance_url/info | json_value "['account']"
}

# Make sure the policy has been loaded. The requests we will be making require
# modifying those records, so they must exist and we must have privilege to 
# modify them. It's reccomended to run this script as the same user who loaded
# the policy.
if [[ `conjur resource exists policy:app` = "false" ]]; then
  echo "Please first run scripts/load_policy from a machine which has the Conjur CLI installed."
  exit 1
fi

# Add some default dummy values to the variables
set_variable_value app%2Fpassword1 `openssl rand -hex 8`
set_variable_value app%2Fpassword2 `openssl rand -hex 8`

# Create the host factory token and create a host identity with it
host_factory_token=`create_host_factory_token app`
host_identity=example-host
api_key=`create_host $host_factory_token $host_identity`

# Create the configuration files for our Java application
echo
sudo scripts/configure_identity.sh "`get_account`" $hostname $host_identity $api_key
