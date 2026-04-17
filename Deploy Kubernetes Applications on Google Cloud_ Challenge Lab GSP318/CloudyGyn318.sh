#!/bin/bash
set -e

# Variables
REPO="valkyrie-docker-repo"
IMAGE="valkyrie-dev"
TAG="v1"

PROJECT_ID=${DEVSHELL_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}
ZONE=$(gcloud config get-value compute/zone)
REGION="${ZONE%-*}"

if [ -z "$PROJECT_ID" ] || [ -z "$ZONE" ]; then
  echo "ERROR: Project or Zone not set"
  exit 1
fi

echo "Project: $PROJECT_ID"
echo "Zone: $ZONE"
echo "Region: $REGION"

# Download source
gsutil cp gs://spls/gsp318/valkyrie-app.tgz .
tar -xzf valkyrie-app.tgz
cd valkyrie-app

# Dockerfile
cat > Dockerfile <<EOF
FROM golang:1.10
WORKDIR /go/src/app
COPY source .
RUN go install -v
ENTRYPOINT ["app","-single=true","-port=8080"]
EOF

# Artifact Registry repo
gcloud artifacts repositories describe $REPO --location=$REGION >/dev/null 2>&1 || \
gcloud artifacts repositories create $REPO \
  --repository-format=docker \
  --location=$REGION

# Image path
IMAGE_PATH="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${IMAGE}:${TAG}"

# Build & push
gcloud builds submit --tag $IMAGE_PATH .

# Update Kubernetes deployment
sed -i "s#IMAGE_HERE#${IMAGE_PATH}#g" k8s/deployment.yaml

# Deploy to GKE
gcloud container clusters get-credentials valkyrie-dev --zone $ZONE

kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

echo "DONE"
