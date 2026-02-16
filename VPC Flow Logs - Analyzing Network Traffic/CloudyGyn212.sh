#!/bin/bash

# Stop on error
set -e

# -----------------------------
# COLORS
# -----------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   VPC Flow Logs Lab Setup Starting${NC}"
echo -e "${BLUE}========================================${NC}"

# -----------------------------
# VARIABLES
# -----------------------------
export PROJECT_ID=$DEVSHELL_PROJECT_ID
export ZONE=${ZONE:-us-central1-a}
export REGION="${ZONE%-*}"

echo -e "${YELLOW}Project:${NC} $PROJECT_ID"
echo -e "${YELLOW}Zone:${NC} $ZONE"
echo -e "${YELLOW}Region:${NC} $REGION"
echo ""

# -----------------------------
# CREATE VPC
# -----------------------------
echo -e "${YELLOW}Creating VPC Network...${NC}"
gcloud compute networks create vpc-net \
  --project=$PROJECT_ID \
  --description="Subscribe to CloudyGyn" \
  --subnet-mode=custom \
  --quiet || true
echo -e "${GREEN}VPC Ready ✔${NC}"

# -----------------------------
# CREATE SUBNET
# -----------------------------
echo -e "${YELLOW}Creating Subnet with Flow Logs...${NC}"
gcloud compute networks subnets create vpc-subnet \
  --project=$PROJECT_ID \
  --network=vpc-net \
  --region=$REGION \
  --range=10.1.3.0/24 \
  --enable-flow-logs \
  --quiet || true
echo -e "${GREEN}Subnet Ready ✔${NC}"

# -----------------------------
# FIREWALL RULE 1
# -----------------------------
echo -e "${YELLOW}Creating Firewall Rule (HTTP + SSH)...${NC}"
gcloud compute firewall-rules create allow-http-ssh \
  --project=$PROJECT_ID \
  --direction=INGRESS \
  --priority=1000 \
  --network=vpc-net \
  --action=ALLOW \
  --rules=tcp:80,tcp:22 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=http-server \
  --quiet || true
echo -e "${GREEN}Firewall Rule Created ✔${NC}"

# -----------------------------
# CREATE VM
# -----------------------------
echo -e "${YELLOW}Creating VM Instance...${NC}"
gcloud compute instances create web-server \
  --zone=$ZONE \
  --project=$PROJECT_ID \
  --machine-type=e2-micro \
  --subnet=vpc-subnet \
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
echo -e "${GREEN}VM Created ✔${NC}"

echo -e "${YELLOW}Waiting for VM to initialize...${NC}"
sleep 40

# -----------------------------
# FIREWALL RULE 2 (FIXED NETWORK)
# -----------------------------
echo -e "${YELLOW}Creating Additional HTTP Firewall Rule...${NC}"
gcloud compute firewall-rules create allow-http \
  --project=$PROJECT_ID \
  --network=vpc-net \
  --allow=tcp:80 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=http-server \
  --description="Allow HTTP traffic" \
  --quiet || true
echo -e "${GREEN}HTTP Rule Ready ✔${NC}"

# -----------------------------
# CREATE BIGQUERY DATASET
# -----------------------------
echo -e "${YELLOW}Creating BigQuery Dataset...${NC}"
bq --location=US mk $PROJECT_ID:bq_vpcflows 2>/dev/null || true
echo -e "${GREEN}BigQuery Dataset Ready ✔${NC}"

# -----------------------------
# GENERATE TRAFFIC
# -----------------------------
echo -e "${YELLOW}Generating Traffic...${NC}"

CP_IP=$(gcloud compute instances describe web-server \
  --zone=$ZONE \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

export MY_SERVER=$CP_IP

for ((i=1;i<=50;i++)); do
  curl -s $MY_SERVER > /dev/null
done

echo -e "${GREEN}Traffic Generated ✔${NC}"

# -----------------------------
# FINAL LINKS (UNCHANGED)
# -----------------------------
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Lab Setup Complete ✅${NC}"
echo -e "${BLUE}========================================${NC}"

echo ""
echo -e "${YELLOW}Open Firewall link:${NC}"
echo "https://console.cloud.google.com/net-security/firewall-manager/firewall-policies/details/allow-http-ssh?project=$DEVSHELL_PROJECT_ID"

echo ""
echo -e "${YELLOW}Open Sink link:${NC}"
echo "https://console.cloud.google.com/logs/query;query=resource.type%3D%22gce_subnetwork%22%0Alog_name%3D%22projects%2F$DEVSHELL_PROJECT_ID%2Flogs%2Fcompute.googleapis.com%252Fvpc_flows%22;cursorTimestamp=2024-06-03T07:20:00.734122029Z;duration=PT1H?project=$DEVSHELL_PROJECT_ID"
