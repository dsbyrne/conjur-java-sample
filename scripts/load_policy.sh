#!/usr/bin/env bash
set -eo pipefail

echo "Loading the Conjur policy for 'app'..."
conjur policy load --as-group security_admin conjur/app.yml
