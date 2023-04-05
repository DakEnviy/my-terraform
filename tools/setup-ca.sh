#!/usr/bin/env bash

set -euo pipefail

# Variables
ER_PATH="$HOME/.dakenviy-tech-ca"
COUNTRY='RU'
ORG='DakEnviy Tech'
BUCKET=''
FOLDER_ID=''

if [[ -d "$ER_PATH" ]]; then
    >&2 echo "CA directory '$ER_PATH' is already exist"
    exit 1
fi

echo 'Creating CA directory...'
mkdir "$ER_PATH"
ln -s /usr/share/easy-rsa/* "$ER_PATH/"
chmod 700 "$ER_PATH"

pushd "$ER_PATH" &>/dev/null

echo 'Building CA...'
./easyrsa init-pki &>/dev/null
cat >> ./pki/vars <<EOT
set_var EASYRSA_REQ_COUNTRY "$COUNTRY"
set_var EASYRSA_REQ_ORG     "$ORG"
set_var EASYRSA_ALGO        "rsa"
set_var EASYRSA_DIGEST      "sha512"
EOT
./easyrsa --batch "--req-cn=$ORG CA" build-ca
./easyrsa --batch gen-crl

echo 'Creating scripts...'
cat >> ./upload-ca.sh <<EOT
#!/usr/bin/env bash

set -euo pipefail

BUCKET='$BUCKET'

echo 'Uploading CA files...'
aws --endpoint-url=https://storage.yandexcloud.net s3 cp ./pki/ca.crt "s3://\$BUCKET/" --content-type text/plain
aws --endpoint-url=https://storage.yandexcloud.net s3 cp ./pki/crl.pem "s3://\$BUCKET/" --content-type text/plain

echo 'Done.'

EOT
chmod +x ./upload-ca.sh
cat >> ./sync-certs.sh <<EOT
#!/usr/bin/env bash

set -euo pipefail

FOLDER_ID='$FOLDER_ID'

contains() {
    for elem in "\${@:2}"; do
        [[ "\$elem" == "\$1" ]] && return
    done
    false
}

create_cert() {
    echo "Creating '\$1' certificate..."

    key_path="./pki/private/\$1.key"
    cert_path="./pki/issued/\$1.crt"
    common_name=\$(openssl x509 -in "\$cert_path" -subject -noout | sed 's/.*CN = //')

    chain_path=\$(mktemp)
    cat "\$cert_path" > "\$chain_path"
    cat ./pki/ca.crt >> "\$chain_path"

    yc certificate-manager certificate create \\
        --folder-id "\$FOLDER_ID" \\
        --name "\$1" \\
        --description "\$common_name" \\
        --key "\$key_path" \\
        --chain "\$chain_path" \\
        &>/dev/null

    rm "\$chain_path"
}

update_cert() {
    echo "Updating '\$1' certificate..."

    key_path="./pki/private/\$1.key"
    cert_path="./pki/issued/\$1.crt"
    common_name=\$(openssl x509 -in "\$cert_path" -subject -noout | sed 's/.*CN = //')

    chain_path=\$(mktemp)
    cat "\$cert_path" > "\$chain_path"
    cat ./pki/ca.crt >> "\$chain_path"

    yc certificate-manager certificate update \\
        --folder-id "\$FOLDER_ID" \\
        --name "\$1" \\
        --description "\$common_name" \\
        --key "\$key_path" \\
        --chain "\$chain_path" \\
        &>/dev/null

    rm "\$chain_path"
}

delete_cert() {
    echo "Deleting '\$1' certificate..."

    yc certificate-manager certificate delete \\
        --folder-id "\$FOLDER_ID" \\
        --name "\$1" \\
        &>/dev/null
}

issued_cert_names=\$(find ./pki/issued/ -type f -name '*.crt' -exec basename '{}' .crt \\;)
imported_cert_names=\$(yc certificate-manager certificate list --folder-id "\$FOLDER_ID" --format json | jq -r '.[].name')

issued_cert_names=(\$issued_cert_names)
imported_cert_names=(\$imported_cert_names)

for cert_name in "\${issued_cert_names[@]}"; do
    if contains "\$cert_name" "\${imported_cert_names[@]}"; then
        update_cert "\$cert_name"
    else
        create_cert "\$cert_name"
    fi
done

for cert_name in "\${imported_cert_names[@]}"; do
    if ! contains "\$cert_name" "\${issued_cert_names[@]}"; then
        delete_cert "\$cert_name"
    fi
done

echo 'Done.'

EOT
chmod +x ./sync-certs.sh

popd &>/dev/null

echo 'Done.'

