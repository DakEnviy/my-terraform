#!/usr/bin/env bash

set -eo pipefail

source "${BASH_SOURCE%/*}/../../bin/utils.sh"

ensure_yc_token

terraform "$@"

