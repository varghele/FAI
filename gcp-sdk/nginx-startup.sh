#!/bin/bash

# Update package lists and install necessary packages: Nginx, Git, Python, and pip
sudo apt update
sudo apt install nginx python3-pip -y
sudo apt install -y git

# Install Flask and gunicorn to handle form uploads to the GCP bucket
sudo pip3 install Flask gunicorn google-cloud-storage

# Set up the directory for the Flask app
FLASK_APP_DIR=~/home/$USER/flask-app

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
sudo mkdir -p ~/tmp/website
sudo git clone $GITHUB_REPO ~/tmp/website
sudo mkdir -p ~/var/www/html/ && sudo cp -a ~/tmp/website/html/* ~/var/www/html/
sudo mkdir -p $FLASK_APP_DIR && sudo cp -a ~/tmp/website/flask/* $FLASK_APP_DIR
# sudo cp -a ~/tmp/website/* $FLASK_APP_DIR
sudo rm -rf ~/tmp/website  # Clean up the temporary directory

# Restart Nginx to serve the new content
sudo systemctl restart nginx

# Enable and start the Flask app as a systemd service
sudo systemctl daemon-reload
sudo systemctl start flask_app
sudo systemctl enable flask_app

# Enable Nginx site and restart Nginx
sudo ln -s /etc/nginx/sites-available/flask_app /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Bind Flask to Gunicorn, bind port 8080 to 127.0.0.1
#sudo gunicorn --bind 127.0.0.1:8080 app:app