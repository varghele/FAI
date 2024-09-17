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
EXTERNAL_IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)

# Now you can use $EXTERNAL_IP in your script
echo "The external IP is: $EXTERNAL_IP"

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

# Create Flask app as a systemd service to run with Gunicorn
cat <<EOF | sudo tee /etc/systemd/system/flask_app.service
[Unit]
Description=Gunicorn instance to serve Flask app
After=network.target

[Service]
User=$USER
WorkingDirectory=$FLASK_APP_DIR
ExecStart=/usr/local/bin/gunicorn --workers 3 --bind 127.0.0.1:8080 app:app

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the Flask app as a systemd service
sudo systemctl daemon-reload
sudo systemctl start flask_app
sudo systemctl enable flask_app

# Create Nginx server block to reverse proxy traffic to Flask running on Gunicorn
cat <<EOF | sudo tee /etc/nginx/sites-available/flask_app
server {
    listen 80;
    server_name $EXTERNAL_IP;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable Nginx site and restart Nginx
sudo ln -s /etc/nginx/sites-available/flask_app /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Firewall configuration (if needed): Allow HTTP traffic (port 80)
sudo ufw allow 'Nginx Full'

# Bind Flask to Gunicorn, bind port 8080 to 127.0.0.1
# sudo gunicorn --bind 127.0.0.1:8080 app:app