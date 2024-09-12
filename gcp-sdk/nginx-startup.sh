#!/bin/bash

# Update package lists and install necessary packages: Nginx, Git, Python, and pip
sudo apt update
sudo apt install nginx python3-pip -y
sudo apt install -y git

# Install Flask and gunicorn to handle form uploads to the GCP bucket
sudo pip3 install Flask gunicorn google-cloud-storage

# Set up the directory for the Flask app
FLASK_APP_DIR=/home/$USER/flask-app
sudo mkdir -p $FLASK_APP_DIR

# Enable and start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Set variables for the project
#PROJECT_DIR="/home/mgmfi/django_project"  # Change this to your project directory
GITHUB_REPO=https://github.com/varghele/FAI.git
GCP_BUCKET="fischerai-1h1hnoesy-bucket"                # Replace with your GCS bucket name
USER="mgmfi"
# SERVICE_ACCOUNT_JSON="/path/to/your/service-account.json"  # Path to your GCS service account
#DOMAIN="fischerai.com"                         # Replace with your domain or VM's public IP

# Clone the GitHub repository and copy files to the Nginx web directory and Flask directory
sudo git clone $GITHUB_REPO /tmp/website
sudo cp -r /tmp/website/html/* /var/www/html/
sudo cp -r /tmp/website/flask/* $FLASK_APP_DIR
sudo rm -rf /tmp/website  # Clean up the temporary directory



# Restart Nginx to serve the new content
sudo systemctl restart nginx

# Bind Flask to Gunicorn, bind port 8080 to 127.0.0.1
sudo gunicorn --bind 127.0.0.1:8080 app:app