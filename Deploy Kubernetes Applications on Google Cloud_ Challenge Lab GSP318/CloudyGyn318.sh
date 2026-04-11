#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ---------- Colors ----------
RED=$(tput setaf 1 2>/dev/null || echo '')
GREEN=$(tput setaf 2 2>/dev/null || echo '')
YELLOW=$(tput setaf 3 2>/dev/null || echo '')
BLUE=$(tput setaf 4 2>/dev/null || echo '')
CYAN=$(tput setaf 6 2>/dev/null || echo '')
BOLD=$(tput bold 2>/dev/null || echo '')
RESET=$(tput sgr0 2>/dev/null || echo '')

echo "${CYAN}${BOLD}🚀 Starting GSP318 Valkyrie Deployment${RESET}"
echo "${YELLOW}👉 Subscribe to CloudyGyn${RESET}"
echo

# ---------- Defaults ----------
REPO="valkyrie-repo"
IMG="valkyrie-app"
TAG="v1"
REGION="us-west1"
ZONE="us-west1-b"
CLUSTER="valkyrie-dev"

# ---------- Project ----------
PROJECT_ID=${DEVSHELL_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null || true)}

if [ -z "$PROJECT_ID" ]; then
  echo "${RED}❌ No project set${RESET}"
  exit 1
fi

echo "${GREEN}Project: $PROJECT_ID${RESET}"

# ---------- Enable APIs (FIXED) ----------
echo "${BLUE}Enabling APIs...${RESET}"
gcloud services enable \
  artifactregistry.googleapis.com \
  container.googleapis.com \
  cloudbuild.googleapis.com

# ---------- Get Source ----------
echo "${BLUE}Downloading source...${RESET}"
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

echo "${CYAN}Image: $IMAGE${RESET}"

# ---------- Artifact Registry (FIXED) ----------
gcloud artifacts repositories describe "$REPO" --location="$REGION" >/dev/null 2>&1 || \
gcloud artifacts repositories create "$REPO" \
  --repository-format=docker \
  --location="$REGION" \
  --description="GSP318 repo"

# ---------- Auth ----------
gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet || true

# ---------- Build ----------
echo "${BLUE}Building image...${RESET}"
gcloud builds submit --tag "$IMAGE" .

# ---------- Update YAML ----------
sed -i "s#IMAGE_HERE#${IMAGE}#g" k8s/deployment.yaml

# ---------- Cluster ----------
echo "${BLUE}Checking cluster...${RESET}"

gcloud container clusters get-credentials "$CLUSTER" --zone "$ZONE" || \
gcloud container clusters create "$CLUSTER" \
  --zone "$ZONE" \
  --num-nodes=1

# ---------- Deploy ----------
echo "${BLUE}Deploying...${RESET}"
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# ---------- Get Service ----------
echo "${CYAN}Waiting for external IP...${RESET}"

for i in {1..30}; do
  IP=$(kubectl get svc -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  if [ -n "$IP" ]; then
    echo "${GREEN}✅ Application URL: http://$IP${RESET}"
    break
  fi
  sleep 5
done

echo
echo "${GREEN}${BOLD}🎉 GSP318 DEPLOYMENT COMPLETE${RESET}"
echo "${YELLOW}👉 Subscribe to CloudyGyn${RESET}"
