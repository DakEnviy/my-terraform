SA_SECRET_NAME='sa-secret'
BUCKET_PREFIX='terraform-state-'

ensure_sa() {
    if [[ -z "$YC_PROFILE" ]]; then
        >&2 echo 'YC_PROFILE variable is empty! You have to fill it.'
        >&2 echo "Example: YC_PROFILE='<yc_profile>' $0 $@"
        exit 1
    fi

    if [[ -z "$YC_FOLDER_ID" ]]; then
        echo 'Varialbe YC_FOLDER_ID is missing. Trying to retrieve it...'
        sa_id=$(yc config profile get "$YC_PROFILE" | yq -r '.["service-account-key"].service_account_id')
        folder_id=$(\
            yc --profile "$YC_PROFILE" iam service-account get --id "$sa_id" --format json | \
            jq -r '.folder_id'\
        )

        export YC_FOLDER_ID="$folder_id"
        echo 'YC_FOLDER_ID variable is exported.'
    fi
}

ensure_yc_token() {
    ensure_sa

    echo 'Creating YC token...'
    yc_token=$(yc --profile "$YC_PROFILE" iam create-token)

    export YC_TOKEN="$yc_token"
    echo 'YC_TOKEN variable is exported.'
}

ensure_storage_variables() {
    ensure_sa

    echo 'Reading SA secret...'
    sa_secret_entries=$(\
        yc --profile "$YC_PROFILE" --folder-id "$YC_FOLDER_ID" lockbox payload get --name "$SA_SECRET_NAME" --format json | \
        jq -r '.entries'\
    )
    storage_access_key=$(\
        echo "$sa_secret_entries" | \
        jq -r '.[] | select(.key == "storage_access_key").text_value'
    )
    storage_secret_key=$(\
        echo "$sa_secret_entries" | \
        jq -r '.[] | select(.key == "storage_secret_key").text_value'
    )

    export YC_STORAGE_ACCESS_KEY="$storage_access_key"
    export YC_STORAGE_SECRET_KEY="$storage_secret_key"
    export AWS_ACCESS_KEY_ID="$storage_access_key"
    export AWS_SECRET_ACCESS_KEY="$storage_secret_key"
    echo 'Storage variables are exported.'
}

ensure_tf_bucket() {
    ensure_sa

    echo 'Finding bucket for terraform...'
    tf_bucket=$(\
        yc --profile "$YC_PROFILE" --folder-id "$YC_FOLDER_ID" storage bucket list --format json | \
        jq -r ".[] | select(.name | startswith(\"$BUCKET_PREFIX\")).name"\
    )

    export TF_BUCKET="$tf_bucket"
    echo 'TF_BUCKET variable is exported.'
}

