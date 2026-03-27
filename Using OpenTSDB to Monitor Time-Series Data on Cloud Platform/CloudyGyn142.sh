#!/bin/bash

# Set variables
ZONE=$(gcloud config get-value compute/zone)
PROJECT_ID=$(gcloud config get-value project)
REGION="${ZONE%-*}"
BIGTABLE_INSTANCE_ID=bt-opentsdb
AR_REPO=opentsdb-bt-repo

# Set zone for gcloud
gcloud config set compute/zone $ZONE

# Clone the OpenTSDB repo
git clone https://github.com/GoogleCloudPlatform/opentsdb-bigtable.git
cd opentsdb-bigtable

# Create Bigtable instance
gcloud bigtable instances create ${BIGTABLE_INSTANCE_ID} \
  --cluster-config=id=${BIGTABLE_INSTANCE_ID}-${ZONE},zone=${ZONE},nodes=1 \
  --display-name=OpenTSDB

# Create GKE cluster
gcloud container clusters create opentsdb-cluster \
  --zone=$ZONE \
  --machine-type e2-standard-4 \
  --scopes "https://www.googleapis.com/auth/cloud-platform"

# Connect to the cluster
gcloud container clusters get-credentials opentsdb-cluster --zone=$ZONE

# Create Artifact Registry
gcloud artifacts repositories create ${AR_REPO} \
  --repository-format=docker \
  --location=${REGION} \
  --description="OpenTSDB on bigtable container images"

# Authenticate Docker with Artifact Registry
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# Build the OpenTSDB Docker image
SERVER_IMAGE_NAME=opentsdb-server-bigtable
SERVER_IMAGE_TAG=2.4.1

gcloud builds submit \
  --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/${AR_REPO}/${SERVER_IMAGE_NAME}:${SERVER_IMAGE_TAG} \
  build

# Generate the time series data
export GEN_IMAGE_NAME=opentsdb-timeseries-generate
export GEN_IMAGE_TAG=0.1

cd generate-ts
./build-cloud.sh
cd ..

# Deploy configurations to Kubernetes
envsubst < configmaps/opentsdb-config.yaml.tpl | kubectl apply -f -
envsubst < jobs/opentsdb-init.yaml.tpl | kubectl apply -f -

# Wait for the OpenTSDB init job to complete
kubectl wait --for=condition=complete job/opentsdb-init --timeout=120s

# Get the logs from the initialization pod
OPENTSDB_INIT_POD=$(kubectl get pods --selector=job-name=opentsdb-init \
  --output=jsonpath={.items..metadata.name})
kubectl logs $OPENTSDB_INIT_POD

# Deploy OpenTSDB write and read deployments
envsubst < deployments/opentsdb-write.yaml.tpl | kubectl apply -f -
envsubst < deployments/opentsdb-read.yaml.tpl | kubectl apply -f -

# Create services for OpenTSDB
kubectl apply -f services/opentsdb-write.yaml
kubectl apply -f services/opentsdb-read.yaml

# Deploy time series generator and Grafana
envsubst < deployments/generate.yaml.tpl | kubectl apply -f -
kubectl apply -f configmaps/grafana.yaml
kubectl apply -f deployments/grafana.yaml

# Final status of pods, services, and deployments
kubectl get pods
kubectl get services
kubectl get deployments

echo "The lab has been completed successfully!"