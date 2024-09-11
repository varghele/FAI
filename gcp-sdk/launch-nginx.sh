#!/bin/bash

# Set variables
PROJECT_ID=<your-project-id>         # Replace with your GCP project ID
ZONE=us-central1-a                   # Replace with your preferred zone
INSTANCE_NAME=nginx-instance
MACHINE_TYPE=e2-micro                # Small machine type (change as needed)
GITHUB_REPO=https://github.com/username/repo.git   # Replace with your GitHub repository URL

# Set GCP project (replace with your project ID)
gcloud config set project $PROJECT_ID

# Create a new VM instance
gcloud compute instances create $INSTANCE_NAME \
    --zone=$ZONE \
    --machine-type=$MACHINE_TYPE \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --boot-disk-size=10GB \
    --tags=http-server

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
