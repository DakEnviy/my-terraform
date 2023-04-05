#!/usr/bin/env bash

set -eo pipefail

source "${BASH_SOURCE%/*}/utils.sh"

ensure_storage_variables
ensure_tf_bucket

TF_CLI_CONFIG_FILE="${BASH_SOURCE%/*}/.terraformrc" \
    terraform init "$@" \
    -backend-config="bucket=$TF_BUCKET" \
    -backend-config="access_key=$YC_STORAGE_ACCESS_KEY" \
    -backend-config="secret_key=$YC_STORAGE_SECRET_KEY"

