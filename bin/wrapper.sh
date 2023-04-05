#!/usr/bin/env bash

set -eo pipefail

source "${BASH_SOURCE%/*}/utils.sh"

ensure_yc_token
ensure_storage_variables
ensure_tf_bucket

TF_CLI_CONFIG_FILE="${BASH_SOURCE%/*}/.terraformrc" \
    terraform "$@" -var "inputs_bucket=$TF_BUCKET"

