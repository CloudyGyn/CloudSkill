#!/bin/bash
set -e

# Variables
REPO="valkyrie-repo"
IMAGE="valkyrie-app"
TAG="v1"
PROJECT_ID=$(gcloud config get-value project)
ZONE=$(gcloud config get-value compute/zone)
REGION="${ZONE%-*}"

# Download app
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

# Create repo if needed
gcloud artifacts repositories describe $REPO --location=$REGION || \
gcloud artifacts repositories create $REPO \
  --repository-format=docker \
  --location=$REGION

# Build & push
IMAGE_PATH="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$TAG"
gcloud builds submit --tag $IMAGE_PATH .

# Update deployment
sed -i "s#IMAGE_HERE#$IMAGE_PATH#g" k8s/deployment.yaml

# Deploy
gcloud container clusters get-credentials valkyrie-dev --zone $ZONE
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

echo "✅ Done"