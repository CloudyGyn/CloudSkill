#!/bin/bash
set -e  # Exit immediately if any command fails
set -o pipefail

echo "🚀 Starting OpenTSDB Lab Setup..."

# --------------------------
# 1️⃣ Set essential variables
# --------------------------
export ZONE=$(gcloud config get-value compute/zone)
export PROJECT_ID=$(gcloud config get-value project)
export REGION="${ZONE%-*}"
export BIGTABLE_INSTANCE_ID=bt-opentsdb
export AR_REPO=opentsdb-bt-repo

echo "📌 Project: $PROJECT_ID | Zone: $ZONE | Region: $REGION"

# --------------------------
# 2️⃣ Set GCP zone
# --------------------------
gcloud config set compute/zone $ZONE

# --------------------------
# 3️⃣ Clone OpenTSDB repo
# --------------------------
git clone https://github.com/GoogleCloudPlatform/opentsdb-bigtable.git
cd opentsdb-bigtable

# --------------------------
# 4️⃣ Create Bigtable instance
# --------------------------
echo "🗄️ Creating Bigtable instance..."
gcloud bigtable instances create ${BIGTABLE_INSTANCE_ID} \
  --cluster-config=id=${BIGTABLE_INSTANCE_ID}-${ZONE},zone=${ZONE},nodes=1 \
  --display-name=OpenTSDB

# --------------------------
# 5️⃣ Create GKE cluster
# --------------------------
echo "🖥️ Creating GKE cluster..."
gcloud container clusters create opentsdb-cluster \
  --zone=$ZONE \
  --machine-type e2-standard-4 \
  --scopes "https://www.googleapis.com/auth/cloud-platform"

# Fetch cluster credentials for kubectl
gcloud container clusters get-credentials opentsdb-cluster --zone=$ZONE

# --------------------------
# 6️⃣ Create Artifact Registry repo
# --------------------------
echo "📦 Creating Artifact Registry repo..."
gcloud artifacts repositories create ${AR_REPO} \
  --repository-format=docker \
  --location=${REGION} \
  --description="OpenTSDB on Bigtable container images"

# Authenticate Docker with Artifact Registry
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# --------------------------
# 7️⃣ Build Docker images
# --------------------------
SERVER_IMAGE_NAME=opentsdb-server-bigtable
SERVER_IMAGE_TAG=2.4.1

echo "🐳 Building OpenTSDB server image..."
gcloud builds submit \
  --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/${AR_REPO}/${SERVER_IMAGE_NAME}:${SERVER_IMAGE_TAG} \
  build

GEN_IMAGE_NAME=opentsdb-timeseries-generate
GEN_IMAGE_TAG=0.1

cd generate-ts
./build-cloud.sh
cd ..

# --------------------------
# 8️⃣ Deploy OpenTSDB ConfigMaps and Jobs
# --------------------------
echo "⚙️ Deploying ConfigMaps and init job..."
envsubst < configmaps/opentsdb-config.yaml.tpl | kubectl apply -f -
envsubst < jobs/opentsdb-init.yaml.tpl | kubectl apply -f -

# Wait for the init job to complete
kubectl wait --for=condition=complete job/opentsdb-init --timeout=120s

# Show logs of init pod
OPENTSDB_INIT_POD=$(kubectl get pods --selector=job-name=opentsdb-init \
  --output=jsonpath={.items..metadata.name})
kubectl logs $OPENTSDB_INIT_POD

# --------------------------
# 9️⃣ Deploy OpenTSDB write/read deployments
# --------------------------
echo "📤 Deploying write/read deployments..."
envsubst < deployments/opentsdb-write.yaml.tpl | kubectl apply -f -
envsubst < deployments/opentsdb-read.yaml.tpl | kubectl apply -f -

# Deploy services
kubectl apply -f services/opentsdb-write.yaml
kubectl apply -f services/opentsdb-read.yaml

# --------------------------
# 🔟 Deploy generator and Grafana
# --------------------------
echo "📊 Deploying time-series generator and Grafana..."
envsubst < deployments/generate.yaml.tpl | kubectl apply -f -
kubectl apply -f configmaps/grafana.yaml
kubectl apply -f deployments/grafana.yaml

# --------------------------
# ✅ Final status
# --------------------------
echo "🎉 The lab has been completed successfully!"
kubectl get pods
kubectl get services
kubectl get deployments
