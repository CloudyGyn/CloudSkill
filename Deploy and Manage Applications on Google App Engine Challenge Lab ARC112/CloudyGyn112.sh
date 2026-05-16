#!/bin/bash

# Auto-detect project ID and default compute zone
export PROJECT_ID=$(gcloud config get-value project)
export ZONE=$(gcloud compute instances list --filter="name=lab-setup" --format="value(zone)")

if [ -z "$ZONE" ]; then
    echo "❌ Error: Could not automatically find the zone for 'lab-setup' VM."
    echo "Please set it manually using: export ZONE='your-zone'"
    exit 1
fi

echo "🚀 Starting remote setup for Project: $PROJECT_ID in Zone: $ZONE"

# 1. Create a deployment script payload
cat << 'EOF' > vm_payload.sh
#!/bin/bash
echo "🖥️ Inside VM: Cloning Python Hello World repository..."
cd ~
rm -rf python-docs-samples

# FIXED LINK: The full path needed to download the repository
git clone https://github.com

# Navigate directly to the Python 3 App Engine starter app
cd ~/python-docs-samples/appengine/standard_python3/hello_world

echo "📦 Initializing App Engine Region..."
# Checks if App Engine is already created; if not, initializes it
gcloud app describe >/dev/null 2>&1 || gcloud app create --region=us-central --quiet

echo "🚀 Deploying to Google App Engine..."
gcloud app deploy app.yaml --quiet
EOF

# 2. Push payload file to the target lab VM 
echo "📤 Injecting code script into lab-setup instance..."
gcloud compute scp vm_payload.sh lab-setup:~ --zone=$ZONE --quiet

# 3. Trigger execution on the VM remotely via SSH channel
echo "⚡ Executing installation routine inside the VM environment..."
gcloud compute ssh lab-setup --zone=$ZONE --command="bash ~/vm_payload.sh" --quiet

# 4. Cleanup local working environment
rm -f vm_payload.sh
echo "🎉 Setup successfully triggered! Check your lab completion progress status now."