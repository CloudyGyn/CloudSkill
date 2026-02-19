#!/bin/bash

echo "Enter zone (example: us-central1-a):"
read ZONE
export ZONE

echo "Creating Blue & Green servers..."

# Create Blue VM
gcloud compute instances create blue \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --machine-type=e2-micro \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
  --metadata=enable-oslogin=true \
  --tags=web-server \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --quiet

# Create Green VM
gcloud compute instances create green \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --machine-type=e2-micro \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
  --metadata=enable-oslogin=true \
  --tags=web-server \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --quiet

# Create Firewall Rule
gcloud compute firewall-rules create allow-http-web-server \
  --project=$DEVSHELL_PROJECT_ID \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --allow=tcp:80,icmp \
  --source-ranges=0.0.0.0/0 \
  --target-tags=web-server \
  --quiet

# Create Test VM
gcloud compute instances create test-vm \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --machine-type=e2-micro \
  --subnet=default \
  --quiet

# Create Service Account
gcloud iam service-accounts create network-admin \
  --description="Service account for Network Admin role" \
  --display-name="Network-admin" \
  --quiet

# Assign Network Admin Role
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=serviceAccount:network-admin@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/compute.networkAdmin \
  --quiet

# Create Key
gcloud iam service-accounts keys create credentials.json \
  --iam-account=network-admin@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
  --quiet

# Setup Blue Server
cat > bluessh.sh <<'EOF'
sudo apt-get update -y
sudo apt-get install nginx-light -y
sudo sed -i '14c\<h1>Welcome to the blue server!</h1>' /var/www/html/index.nginx-debian.html
sudo systemctl restart nginx
EOF

gcloud compute scp bluessh.sh blue:/tmp --zone=$ZONE --quiet
gcloud compute ssh blue --zone=$ZONE --quiet --command="bash /tmp/bluessh.sh"

# Setup Green Server
cat > greenssh.sh <<'EOF'
sudo apt-get update -y
sudo apt-get install nginx-light -y
sudo sed -i '14c\<h1>Welcome to the green server!</h1>' /var/www/html/index.nginx-debian.html
sudo systemctl restart nginx
EOF

gcloud compute scp greenssh.sh green:/tmp --zone=$ZONE --quiet
gcloud compute ssh green --zone=$ZONE --quiet --command="bash /tmp/greenssh.sh"

echo -e "\033[34m====================================\033[0m"
echo -e "\033[32m   Script execution completed successfully. ✅\033[0m"
echo -e "\033[34m====================================\033[0m"
