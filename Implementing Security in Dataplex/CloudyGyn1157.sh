#!/bin/bash

gcloud services enable dataplex.googleapis.com datacatalog.googleapis.com

gcloud dataplex lakes create customer-info-lake \
  --location=$REGION \
  --display-name="Customer Info Lake"

gcloud alpha dataplex zones create customer-raw-zone \
            --location=$REGION --lake=customer-info-lake \
            --resource-location-type=SINGLE_REGION --type=RAW \
            --display-name="Customer Raw Zone"

gcloud dataplex assets create customer-online-sessions --location=$REGION \
            --lake=customer-info-lake --zone=customer-raw-zone \
            --resource-type=STORAGE_BUCKET \
            --resource-name=projects/$DEVSHELL_PROJECT_ID/buckets/$DEVSHELL_PROJECT_ID-bucket \
            --display-name="Customer Online Sessions"


# Final message

echo "${CYAN}${BOLD}Click here: "${RESET}""${BLUE}${BOLD}"https://console.cloud.google.com/dataplex/secure?resourceName=projects%2F$DEVSHELL_PROJECT_ID%2Flocations%2F$REGION%2Flakes%2Fcustomer-info-lake&project=$DEVSHELL_PROJECT_ID""${RESET}"

            
echo "✅ Script execution completed"


echo
echo "${GREEN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Future Cloud Skill${RESET_FORMAT}"
echo
