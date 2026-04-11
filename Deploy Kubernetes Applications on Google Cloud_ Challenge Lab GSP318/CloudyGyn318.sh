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

echo "${CYAN}${BOLD}🚀 Starting Valkyrie Lab Automation${RESET}"
echo "${YELLOW}${BOLD}👉 Please Subscribe to CloudyGyn${RESET}"
echo

# ---------- Defaults ----------

DEFAULT_REPO="valkyrie-docker-repo"
DEFAULT_IMG="valkyrie-dev"
DEFAULT_TAG="v0.0.1"
DEFAULT_REGION="us-west1"
DEFAULT_ZONE="us-west1-b"

read -p "Repository Name [${DEFAULT_REPO}]: " REPO
REPO=${REPO:-$DEFAULT_REPO}

read -p "Docker Image Name [${DEFAULT_IMG}]: " DCKR_IMG
DCKR_IMG=${DCKR_IMG:-$DEFAULT_IMG}

read -p "Tag [${DEFAULT_TAG}]: " TAG
TAG=${TAG:-$DEFAULT_TAG}

read -p "Region [${DEFAULT_REGION}]: " REGION
REGION=${REGION:-$DEFAULT_REGION}

read -p "Zone [${DEFAULT_ZONE}]: " ZONE
ZONE=${ZONE:-$DEFAULT_ZONE}

# ---------- Project ----------

PROJECT_ID=${DEVSHELL_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null || true)}
if [ -z "$PROJECT_ID" ]; then
echo "${RED}❌ No project set. Run: gcloud config set project <PROJECT_ID>${RESET}"
exit 1
fi

echo "${GREEN}Using Project: $PROJECT_ID${RESET}"

# ---------- Enable APIs ----------

echo "${BLUE}Enabling required APIs...${RESET}"
gcloud services enable \
  artifactregistry.googleapis.com \
  container.googleapis.com \
  cloudbuild.googleapis.com

# ---------- Download App ----------

echo "${BLUE}Downloading app source...${RESET}"
if [ ! -f valkyrie-app.tgz ] && [ ! -d valkyrie-app ]; then
gsutil cp gs://cloud-training/gsp318/valkyrie-app.tgz . || 
gsutil cp gs://spls/gsp318/valkyrie-app.tgz .
fi

if [ -f valkyrie-app.tgz ] && [ ! -d valkyrie-app ]; then
tar -xzf valkyrie-app.tgz
fi

cd valkyrie-app

# ---------- Dockerfile ----------

cat > Dockerfile <<'EOF'
FROM golang:1.10
WORKDIR /go/src/app
COPY source .
RUN go install -v
ENTRYPOINT ["app","-single=true","-port=8080"]
EOF

# ---------- Image Path ----------

IMAGE_PATH="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${DCKR_IMG}:${TAG}"
echo "${CYAN}Image: $IMAGE_PATH${RESET}"

# ---------- Artifact Registry ----------

if ! gcloud artifacts repositories describe "$REPO" --location="$REGION" >/dev/null 2>&1; then
echo "${YELLOW}Creating Artifact Registry repo...${RESET}"
gcloud artifacts repositories create "$REPO" 
--repository-format=docker 
--location="$REGION" 
--description="valkyrie repo"
else
echo "${GREEN}Repo already exists${RESET}"
fi

gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet || true

# ---------- Build & Push ----------

echo "${BLUE}Building with Cloud Build...${RESET}"
gcloud builds submit --tag "$IMAGE_PATH" .

# ---------- Local Docker Test ----------

if command -v docker >/dev/null 2>&1; then
echo "${BLUE}Running local test...${RESET}"
docker rm -f "${DCKR_IMG}*${TAG}" 2>/dev/null || true
docker build -t "${DCKR_IMG}:${TAG}" .
docker run -d -p 8080:8080 --name "${DCKR_IMG}*${TAG}" "${DCKR_IMG}:${TAG}" 
|| echo "${YELLOW}Docker run skipped (port busy)${RESET}"
fi

# ---------- Update Deployment ----------

if [ ! -f k8s/deployment.yaml ]; then
echo "${RED}❌ deployment.yaml not found${RESET}"
exit 1
fi

sed -i.bak "s#IMAGE_HERE#${IMAGE_PATH}#g" k8s/deployment.yaml

# ---------- GKE Cluster ----------

CLUSTER="valkyrie-dev"

if ! gcloud container clusters list --format="value(name)" | grep -q "^$CLUSTER$"; then
echo "${YELLOW}Creating GKE cluster...${RESET}"
gcloud container clusters create "$CLUSTER" 
--zone "$ZONE" 
--num-nodes=1
else
echo "${GREEN}Cluster exists${RESET}"
fi

gcloud container clusters get-credentials "$CLUSTER" --zone "$ZONE"

# ---------- Deploy ----------

echo "${BLUE}Deploying to Kubernetes...${RESET}"
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# ---------- Get Service ----------

echo "${CYAN}Checking service...${RESET}"
SERVICE_NAME=$(kubectl get svc -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)

if [ -n "$SERVICE_NAME" ]; then
echo "${BLUE}Waiting for external IP...${RESET}"
for i in {1..40}; do
EX_IP=$(kubectl get svc "$SERVICE_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
if [ -n "$EX_IP" ]; then
echo "${GREEN}✅ App URL: http://$EX_IP${RESET}"
break
fi
sleep 5
done

if [ -z "${EX_IP:-}" ]; then
echo "${YELLOW}⚠️ External IP pending. Run: kubectl get svc${RESET}"
fi
else
echo "${YELLOW}⚠️ Service not detected${RESET}"
fi

echo
echo "${CYAN}${BOLD}👉 Please Subscribe to CloudyGyn${RESET}"
echo "${GREEN}${BOLD}🎉 DONE! Deployment complete.${RESET}"
