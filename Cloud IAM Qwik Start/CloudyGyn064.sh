#!/bin/bash

YELLOW_COLOR="\033[1;33m"
NO_COLOR="\033[0m"

read -p "${YELLOW_COLOR}Enter USERNAME 2 (email): ${NO_COLOR}" USERNAME_2

BUCKET_NAME="${DEVSHELL_PROJECT_ID}-bucket"

gsutil mb -l us -b on gs://$BUCKET_NAME

echo "Subscribe to CloudyGyn" > sample.txt

gsutil cp sample.txt gs://$BUCKET_NAME

gcloud projects remove-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member="user:$USERNAME_2" \
--role="roles/viewer"

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member="user:$USERNAME_2" \
--role="roles/storage.objectViewer"
