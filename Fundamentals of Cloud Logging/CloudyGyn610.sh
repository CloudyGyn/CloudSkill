#!/bin/bash

echo "=== Cloud Setup Script ==="

# Get project info
ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
PROJECT_ID=$(gcloud config get-value project)

echo "Zone: $ZONE | Region: $REGION | Project: $PROJECT_ID"

# Task 1: Create logging metric for 200 responses
echo "Creating logging metric (200 responses)..."
gcloud logging metrics create 200responses \
  --description="Counts 200 OK responses from App Engine default service" \
  --log-filter='resource.type="gae_app" AND resource.labels.module_id="default" AND (protoPayload.status=200 OR httpRequest.status=200)'

# Task 2: Create latency metric
echo "Creating latency metric..."
export DEVSHELL_PROJECT_ID=$PROJECT_ID

cat > latency_metric.yaml <<EOF
name: projects/$DEVSHELL_PROJECT_ID/metrics/latency_metric
description: "latency distribution"
filter: >
  resource.type="gae_app"
  resource.labels.module_id="default"
  (protoPayload.status=200 OR httpRequest.status=200)
valueExtractor: EXTRACT(protoPayload.latency)
metricDescriptor:
  metricKind: DELTA
  valueType: DISTRIBUTION
  unit: "s"
bucketOptions:
  exponentialBuckets:
    numFiniteBuckets: 10
    growthFactor: 2.0
    scale: 0.01
EOF

gcloud logging metrics create latency_metric --config-from-file=latency_metric.yaml

# Task 3: Create VM
echo "Creating VM instance..."
gcloud compute instances create audit-log-vm \
  --zone=$ZONE \
  --machine-type=e2-micro \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --tags=http-server \
  --metadata=startup-script='#!/bin/bash
    apt update
    apt install -y apache2
    systemctl start apache2' \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --quiet

# Task 4: Create BigQuery sink
echo "Creating BigQuery dataset and log sink..."
BQ_DATASET="AuditLogs"

bq mk --dataset $PROJECT_ID:$BQ_DATASET

gcloud logging sinks create AuditLogs \
  bigquery.googleapis.com/projects/$PROJECT_ID/datasets/$BQ_DATASET \
  --log-filter='resource.type="gce_instance" AND logName="projects/'$PROJECT_ID'/logs/cloudaudit.googleapis.com%2Factivity"' \
  --description="Export GCE audit logs to BigQuery"

echo "The lab has been completed successfully."
echo "App Engine Dashboard: https://console.cloud.google.com/appengine?project=$PROJECT_ID"