#!/usr/bin/env bash
set -eo pipefail

# json_value
# Uses python to resolve a value from a JSON blob
json_value () {
  python -c "import json,sys;sys.stdout.write(json.load(sys.stdin)[0]['$1'])"
}

# Make sure the policy has been loaded. The requests we will be making require
# modifying those records, so they must exist and we must have privilege to 
# modify them. It's reccomended to run this script as the same user who loaded
# the policy.
if [[ `conjur resource exists policy:app` = "false" ]]; then
  scripts/load_policy.sh
fi

# Add some default dummy values to the variables
conjur variable values add app/password1 `openssl rand -hex 8`
conjur variable values add app/password2 `openssl rand -hex 8`

# Create a host factory token for the app layer
host_factory_token=`conjur hostfactory token create app | json_value token`

# Enroll a new host using the host factory token
host_id=example-host
host_info="`conjur hostfactory host create $host_factory_token $host_id`"

# Create Conjur configuration files
bash -c "`echo $host_info | conjurize --ssh`"
