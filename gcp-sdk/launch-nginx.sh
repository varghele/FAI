#!/bin/bash

# Set variables
PROJECT_ID=fischerai         #  GCP project ID
ZONE=europe-west10-b                   # Berlin
INSTANCE_NAME=nginx-main
MACHINE_TYPE=e2-micro                # smallest possible
GITHUB_REPO=https://github.com/varghele/FAI/tree/main/html   # point to html folder on main branch

# Set GCP project (replace with your project ID)
gcloud config set project $PROJECT_ID

# Create a new VM instance
gcloud compute instances create $INSTANCE_NAME \
    --zone=$ZONE \
    --machine-type=$MACHINE_TYPE \
    --boot-disk-size=10GB \
    --tags=http-server \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account=506359823535-compute@developer.gserviceaccount.com \
    --create-disk=auto-delete=yes,boot=yes,device-name=instance-20240912-055812,image=projects/debian-cloud/global/images/debian-12-bookworm-v20240910,mode=rw,size=10,type=pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any \

# Allow HTTP traffic (port 80)
gcloud compute firewall-rules create default-allow-http \
    --allow=tcp:80 \
    --target-tags=http-server \
    --description="Allow HTTP traffic on port 80"

# Install Nginx and Git on the VM instance, clone the GitHub repo, and copy files to Nginx web directory
gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command \
    "sudo apt update && \
    sudo apt install -y nginx git && \
    sudo systemctl enable nginx && sudo systemctl start nginx && \
    git clone $GITHUB_REPO /tmp/website && \
    sudo cp -r /tmp/website/* /var/www/html/ && \
    sudo systemctl restart nginx"

# Output the external IP of the instance
EXTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
echo "Nginx is running. Access the website at: http://$EXTERNAL_IP"
