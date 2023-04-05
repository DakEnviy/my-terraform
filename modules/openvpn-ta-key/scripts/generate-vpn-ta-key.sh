#!/usr/bin/env bash

set -exo pipefail

eval "$(jq -r '@sh "SECRET_ID=\(.secret_id)"')"

if [[ -z "$YC_TOKEN" ]]; then
    >&2 echo 'YC_TOKEN variable is empty! You have to fill it to use openvpn-ta-key module.'
    exit 1
fi

secret_response=$(\
    curl -s -X GET -H "Authorization: Bearer $YC_TOKEN" \
    "https://payload.lockbox.api.cloud.yandex.net/lockbox/v1/secrets/$SECRET_ID/payload"\
)
secret_version_id=$(echo "$secret_response" | jq -r '.versionId')

if [[ "$secret_version_id" == 'null' ]]; then
    >&2 echo "Secret '$SECRET_ID' was not found."
    exit 1
fi

ta_key=$(\
    echo "$secret_response" | \
    jq -r '.entries[] | select(.key == "ta_key").textValue' 2>/dev/null || \
    true\
)

if [[ -z "$ta_key" ]]; then
    ta_key=$(openvpn --genkey secret /dev/stdout)
fi

jq -n --arg ta_key "$ta_key" '{ "ta_key": $ta_key }'

