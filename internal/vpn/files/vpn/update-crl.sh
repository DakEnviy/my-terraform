#!/usr/bin/env bash

set -euxo pipefail

ACT_PATH='/etc/openvpn/server/crl.pem'
TMP_PATH='/tmp/crl.pem'

get_hash() {
    md5sum "$1" | cut -d ' ' -f 1
}

replace_crl() {
    mv "$TMP_PATH" "$ACT_PATH"
    systemctl restart openvpn-server@server.service
}

curl -s "https://storage.yandexcloud.net/$CA_BUCKET/crl.pem" > "$TMP_PATH"

if [[ ! -f "$ACT_PATH" ]]; then
    replace_crl
    exit
fi

old_hash=$(get_hash "$ACT_PATH")
new_hash=$(get_hash "$TMP_PATH")

if [[ "$old_hash" != "$new_hash" ]]; then
    replace_crl
fi

