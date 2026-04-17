#!/bin/bash

# ====== SET VARIABLES ======
export DOCKER_IMAGE=valkyrie-app
export TAG_NAME=v1
export REPO_NAME=valkyrie-repo
export ZONE=$(gcloud config get-value compute/zone)
export REGION="${ZONE%-*}"

# ====== AUTH CHECK ======
gcloud auth list

# ====== SETUP MARKING ======
gsutil cat gs://cloud-training/gsp318/marking/setup_marking_v2.sh | bash

# ====== CLONE SOURCE ======
gcloud source repos clone valkyrie-app
cd valkyrie-app

# ====== CREATE DOCKERFILE ======
cat > Dockerfile <<EOF
FROM golang:1.10
WORKDIR /go/src/app
COPY source .
RUN go install -v
ENTRYPOINT ["app","-single=true","-port=8080"]
EOF

# ====== BUILD IMAGE ======
docker build -t $DOCKER_IMAGE:$TAG_NAME .

# ====== STEP 1 ======
cd ..
cd marking
./step1_v2.sh

# ====== RUN CONTAINER ======
cd ..
cd valkyrie-app
docker run -d -p 8080:8080 $DOCKER_IMAGE:$TAG_NAME
sleep 10

# ====== STEP 2 ======
cd ..
cd marking
./step2_v2.sh

# ====== PUSH TO ARTIFACT REGISTRY ======
cd ..
cd valkyrie-app

gcloud artifacts repositories create $REPO_NAME \
    --repository-format=docker \
    --location=$REGION \
    --description="valkyrie repo" \
    --async

gcloud auth configure-docker $REGION-docker.pkg.dev --quiet

echo "Waiting for repo creation..."
sleep 20

IMAGE_ID=$(docker images -q $DOCKER_IMAGE:$TAG_NAME)

docker tag $IMAGE_ID $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$REPO_NAME/$DOCKER_IMAGE:$TAG_NAME

docker push $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$REPO_NAME/$DOCKER_IMAGE:$TAG_NAME

# ====== DEPLOY TO GKE ======
sed -i s#IMAGE_HERE#$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$REPO_NAME/$DOCKER_IMAGE:$TAG_NAME#g k8s/deployment.yaml

gcloud container clusters get-credentials valkyrie-dev --zone $ZONE

kubectl create -f k8s/deployment.yaml
kubectl create -f k8s/service.yaml

echo "✅ GSP318 Lab Completed"
