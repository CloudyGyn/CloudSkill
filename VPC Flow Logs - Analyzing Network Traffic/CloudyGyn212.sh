#!/bin/bash

# Exit on error
set -e

# -----------------------------
# COLORS
# -----------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Cleaning Up VPC Flow Logs Lab${NC}"
echo -e "${BLUE}========================================${NC}"

# -----------------------------
# VARIABLES
# -----------------------------
PROJECT_ID=$(gcloud config get-value project)
ZONE=${ZONE:-us-central1-a}
REGION="${ZONE%-*}"

NETWORK=vpc-net
SUBNET=vpc-subnet
VM_NAME=web-server
FIREWALL_RULE=allow-http-ssh
DATASET=bq_vpcflows
SINK_NAME=vpc-flow-sink

echo -e "${YELLOW}Project:${NC} $PROJECT_ID"
echo -e "${YELLOW}Zone:${NC} $ZONE"
echo -e "${YELLOW}Region:${NC} $REGION"
echo ""

# -----------------------------
# DELETE VM
# -----------------------------
echo -e "${YELLOW}Deleting VM...${NC}"
gcloud compute instances delete $VM_NAME --zone=$ZONE --quiet 2>/dev/null \
    && echo -e "${GREEN}VM deleted ✔${NC}" \
    || echo -e "${RED}VM not found or already deleted ✖${NC}"

# -----------------------------
# DELETE FIREWALL RULE
# -----------------------------
echo -e "${YELLOW}Deleting Firewall Rule...${NC}"
gcloud compute firewall-rules delete $FIREWALL_RULE --quiet 2>/dev/null \
    && echo -e "${GREEN}Firewall rule deleted ✔${NC}" \
    || echo -e "${RED}Firewall rule not found ✖${NC}"

# -----------------------------
# DELETE LOGGING SINK
# -----------------------------
echo -e "${YELLOW}Deleting Logging Sink...${NC}"
gcloud logging sinks delete $SINK_NAME --quiet 2>/dev/null \
    && echo -e "${GREEN}Logging sink deleted ✔${NC}" \
    || echo -e "${RED}Logging sink not found ✖${NC}"

# -----------------------------
# DELETE BIGQUERY DATASET
# -----------------------------
echo -e "${YELLOW}Deleting BigQuery Dataset...${NC}"
bq rm -r -f $PROJECT_ID:$DATASET 2>/dev/null \
    && echo -e "${GREEN}BigQuery dataset deleted ✔${NC}" \
    || echo -e "${RED}Dataset not found ✖${NC}"

# -----------------------------
# DELETE SUBNET
# -----------------------------
echo -e "${YELLOW}Deleting Subnet...${NC}"
gcloud compute networks subnets delete $SUBNET --region=$REGION --quiet 2>/dev/null \
    && echo -e "${GREEN}Subnet deleted ✔${NC}" \
    || echo -e "${RED}Subnet not found ✖${NC}"

# -----------------------------
# DELETE VPC NETWORK
# -----------------------------
echo -e "${YELLOW}Deleting VPC Network...${NC}"
gcloud compute networks delete $NETWORK --quiet 2>/dev/null \
    && echo -e "${GREEN}VPC network deleted ✔${NC}" \
    || echo -e "${RED}VPC network not found ✖${NC}"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Cleanup Complete ✅${NC}"
echo -e "${BLUE}========================================${NC}"


# Exit immediately if a command exits with error
set -e

echo "===== Starting Fully Automated VPC Flow Logs Lab ====="

# -----------------------------
# VARIABLES
# -----------------------------
export PROJECT_ID=$(gcloud config get-value project)
export ZONE=${ZONE:-us-central1-a}
export REGION="${ZONE%-*}"
export NETWORK=vpc-net
export SUBNET=vpc-subnet
export VM_NAME=web-server
export FIREWALL_RULE=allow-http-ssh
export DATASET=bq_vpcflows
export SINK_NAME=vpc-flow-sink

echo "Project: $PROJECT_ID"
echo "Zone: $ZONE"
echo "Region: $REGION"

# -----------------------------
# ENABLE REQUIRED APIS
# -----------------------------
echo "Enabling required APIs..."
gcloud services enable compute.googleapis.com \
    logging.googleapis.com \
    bigquery.googleapis.com

# -----------------------------
# CREATE VPC NETWORK
# -----------------------------
echo "Creating VPC..."
gcloud compute networks create $NETWORK \
    --subnet-mode=custom \
    --description="Custom VPC for Flow Logs Lab" \
    --quiet || true

# -----------------------------
# CREATE SUBNET WITH FLOW LOGS
# -----------------------------
echo "Creating Subnet with Flow Logs..."
gcloud compute networks subnets create $SUBNET \
    --network=$NETWORK \
    --region=$REGION \
    --range=10.1.3.0/24 \
    --enable-flow-logs \
    --quiet || true

# -----------------------------
# CREATE FIREWALL RULE
# -----------------------------
echo "Creating Firewall Rule..."
gcloud compute firewall-rules create $FIREWALL_RULE \
    --network=$NETWORK \
    --direction=INGRESS \
    --priority=1000 \
    --action=ALLOW \
    --rules=tcp:80,tcp:22 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server \
    --quiet || true

# -----------------------------
# CREATE VM INSTANCE
# -----------------------------
echo "Creating VM instance..."
gcloud compute instances create $VM_NAME \
    --zone=$ZONE \
    --machine-type=e2-micro \
    --subnet=$SUBNET \
    --tags=http-server \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --metadata=startup-script='#!/bin/bash
        apt update
        apt install apache2 -y
        systemctl start apache2
        systemctl enable apache2' \
    --labels=server=apache \
    --quiet || true

# -----------------------------
# WAIT FOR VM
# -----------------------------
echo "Waiting for VM to initialize..."
sleep 40

# -----------------------------
# CREATE BIGQUERY DATASET
# -----------------------------
echo "Creating BigQuery dataset..."
bq --location=US mk --dataset $PROJECT_ID:$DATASET || true

# -----------------------------
# CREATE LOGGING SINK (VPC FLOW LOGS → BQ)
# -----------------------------
echo "Creating Logging Sink..."
gcloud logging sinks create $SINK_NAME \
    bigquery.googleapis.com/projects/$PROJECT_ID/datasets/$DATASET \
    --log-filter='resource.type="gce_subnetwork"
                  logName="projects/'$PROJECT_ID'/logs/compute.googleapis.com%2Fvpc_flows"' \
    --quiet || true

# -----------------------------
# GRANT BQ PERMISSIONS TO SINK
# -----------------------------
echo "Granting BigQuery permissions to sink..."

SINK_SA=$(gcloud logging sinks describe $SINK_NAME \
    --format='value(writerIdentity)')

bq show --format=prettyjson $PROJECT_ID:$DATASET > /dev/null

bq update --dataset \
    --add_iam_member=member:$SINK_SA,role:roles/bigquery.dataEditor \
    $PROJECT_ID:$DATASET

# -----------------------------
# GENERATE TRAFFIC
# -----------------------------
echo "Generating HTTP traffic..."

CP_IP=$(gcloud compute instances describe $VM_NAME \
    --zone=$ZONE \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

for i in {1..50}
do
    curl -s http://$CP_IP > /dev/null
done

echo "Traffic generated."

# -----------------------------
# SUCCESS MESSAGE
# -----------------------------
echo "========================================"
echo "LAB SETUP COMPLETE"
echo "========================================"
echo "VM External IP: http://$CP_IP"
echo ""
echo "View Flow Logs:"
echo "https://console.cloud.google.com/logs/query?project=$PROJECT_ID"
echo ""
echo "BigQuery Dataset:"
echo "https://console.cloud.google.com/bigquery?project=$PROJECT_ID"
echo ""
echo "========================================"
