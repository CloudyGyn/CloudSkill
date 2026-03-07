#!/bin/bash

YELLOW_COLOR="\033[1;33m"
NO_COLOR="\033[0m"

BUCKET_NAME="${DEVSHELL_PROJECT_ID}-bucket"

echo -e "${YELLOW_COLOR}Creating bucket...${NO_COLOR}"
gsutil mb -l us -b on gs://$BUCKET_NAME

echo "Subscribe to CloudyGyn" > sample.txt

echo -e "${YELLOW_COLOR}Uploading file...${NO_COLOR}"
gsutil cp sample.txt gs://$BUCKET_NAME

echo -e "${YELLOW_COLOR}Removing viewer role...${NO_COLOR}"
gcloud projects remove-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member="user:$USERNAME_2" \
--role="roles/viewer"

echo -e "${YELLOW_COLOR}Adding storage.objectViewer role...${NO_COLOR}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member="user:$USERNAME_2" \
--role="roles/storage.objectViewer"

echo -e "${YELLOW_COLOR}Completed!${NO_COLOR}"
