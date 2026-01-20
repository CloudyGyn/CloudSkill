#!/bin/bash

set -e

echo "Authenticating user..."
gcloud auth list

PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1   # FIX: hardcode region (Arcade safe)

echo "Project: $PROJECT_ID"
echo "Region: $REGION"

echo "Enabling required services..."
gcloud services enable dataplex.googleapis.com datacatalog.googleapis.com

echo "Waiting for APIs to be ready..."
sleep 60

BUCKET_NAME=${PROJECT_ID}-bucket

echo "Creating Cloud Storage bucket..."
gsutil mb -l $REGION gs://$BUCKET_NAME || echo "Bucket already exists"

echo "Creating Dataplex lake..."
gcloud dataplex lakes create customer-info-lake \
  --location=$REGION \
  --display-name="fcs Info Lake" || echo "Lake already exists"

echo "Creating Dataplex zone..."
gcloud dataplex zones create customer-raw-zone \
  --location=$REGION \
  --lake=customer-info-lake \
  --display-name="fcs Raw Zone" \
  --type=RAW \
  --resource-location-type=SINGLE_REGION || echo "Zone already exists"

echo "Creating Dataplex asset..."
gcloud dataplex assets create customer-online-sessions \
  --location=$REGION \
  --lake=customer-info-lake \
  --zone=customer-raw-zone \
  --display-name="fcs Online Sessions" \
  --resource-type=STORAGE_BUCKET \
  --resource-name=projects/$PROJECT_ID/buckets/$BUCKET_NAME || echo "Asset already exists"

echo
echo "Grant access if prompted:"
echo "https://console.cloud.google.com/dataplex/secure?project=$PROJECT_ID"
echo
echo "✅ Script execution completed"
