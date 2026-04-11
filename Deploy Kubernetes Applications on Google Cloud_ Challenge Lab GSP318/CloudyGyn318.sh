#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ---------- Colors ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${CYAN}${BOLD}🚀 Starting GSP318 Valkyrie Deployment${RESET}"
echo -e "${YELLOW}${BOLD}👉 Subscribe to CloudyGyn${RESET}"
echo

# ---------- Project ----------
PROJECT_ID=${DEVSHELL_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}

if [ -z "$PROJECT_ID" ]; then
  echo -e "${RED}❌ No project set${RESET}"
  exit 1
fi

echo -e "${GREEN}📌 Project: $PROJECT_ID${RESET}"

# ---------- Variables ----------
REGION="us-west1"
ZONE="us-west1-b"
REPO="valkyrie-repo"
IMG="valkyrie-app"
TAG="v1"
CLUSTER="valkyrie-dev"

# ---------- Enable APIs ----------
echo -e "${BLUE}🔧 Enabling APIs...${RESET}"
gcloud services enable artifactregistry.googleapis.com container.googleapis.com cloudbuild.googleapis.com

# ---------- Download App ----------
echo -e "${BLUE}⬇️ Downloading application...${RESET}"
if [ ! -d valkyrie-app ]; then
  gsutil cp gs://cloud-training/gsp318/valkyrie-app.tgz .
  tar -xzf valkyrie-app.tgz
fi

cd valkyrie-app

# ---------- Dockerfile ----------
cat > Dockerfile <<EOF
FROM golang:1.10
WORKDIR /go/src/app
COPY source .
RUN go install -v
ENTRYPOINT ["app","-single=true","-port=8080"]
EOF

# ---------- Image ----------
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${IMG}:${TAG}"

echo -e "${CYAN}📦 Image: $IMAGE${RESET}"

# ---------- Artifact Registry ----------
echo -e "${BLUE}📦 Checking Artifact Registry...${RESET}"
gcloud artifacts repositories describe "$REPO" --location="$REGION" >/dev/null 2>&1 || \
gcloud artifacts repositories create "$REPO" \
  --repository-format=docker \
  --location="$REGION" \
  --description="GSP318 repo"

gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet || true

# ---------- Build ----------
echo -e "${BLUE}🏗️ Building image...${RESET}"
gcloud builds submit --tag "$IMAGE" .

# ---------- Update YAML ----------
sed -i "s#IMAGE_HERE#${IMAGE}#g" k8s/deployment.yaml

# ---------- Cluster ----------
echo -e "${BLUE}☸️ Preparing cluster...${RESET}"
gcloud container clusters get-credentials "$CLUSTER" --zone "$ZONE" || \
gcloud container clusters create "$CLUSTER" --zone "$ZONE" --num-nodes=1

# ---------- Deploy ----------
echo -e "${BLUE}🚀 Deploying to Kubernetes...${RESET}"
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# ---------- External IP ----------
echo -e "${YELLOW}⏳ Waiting for External IP...${RESET}"

for i in {1..30}; do
  IP=$(kubectl get svc -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  if [ ! -z "$IP" ]; then
    echo -e "${GREEN}✅ App URL: http://$IP${RESET}"
    break
  fi
  sleep 5
done

echo
echo -e "${GREEN}${BOLD}🎉 GSP318 Deployment Completed Successfully!${RESET}"
echo -e "${CYAN}${BOLD}👉 Subscribe to CloudyGyn 💙${RESET}"
