#!/bin/bash

# Update package lists and install necessary packages: Nginx, Git, Python, and pip
sudo apt update
sudo apt install -y nginx git python3-pip python3-venv

# Enable and start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Set variables for the project
PROJECT_DIR="/home/yourusername/django_project"  # Change this to your project directory
GITHUB_REPO=https://github.com/varghele/FAI.git
GCP_BUCKET="your-gcp-bucket-name"                # Replace with your GCS bucket name
SERVICE_ACCOUNT_JSON="/path/to/your/service-account.json"  # Path to your GCS service account
DOMAIN="your-domain.com"                         # Replace with your domain or VM's public IP

# Clone the GitHub repository and copy files to the Nginx web directory
git clone $GITHUB_REPO /tmp/website
sudo cp -r /tmp/website/html/* /var/www/html/
sudo rm -rf /tmp/website  # Clean up the temporary directory

# Restart Nginx to serve the new content
sudo systemctl restart nginx

# Create the Django project directory if it doesn't exist
mkdir -p $PROJECT_DIR

# Create and activate the virtual environment
python3 -m venv $PROJECT_DIR/venv
source $PROJECT_DIR/venv/bin/activate

# Install Django, Gunicorn, and Google Cloud Storage SDK
pip install django gunicorn google-cloud-storage

# If your Django project already exists, skip the next step
# Uncomment the following line to create a new Django project
# django-admin startproject myproject $PROJECT_DIR

# Change to the project directory and run Django migrations
cd $PROJECT_DIR
python manage.py migrate
python manage.py collectstatic --noinput

# Configure Gunicorn as a service
sudo tee /etc/systemd/system/gunicorn.service > /dev/null <<EOF
[Unit]
Description=gunicorn daemon for Django project
After=network.target

[Service]
User=yourusername  # Change this to your username
Group=www-data
WorkingDirectory=$PROJECT_DIR
ExecStart=$PROJECT_DIR/venv/bin/gunicorn --workers 3 --bind unix:$PROJECT_DIR/gunicorn.sock myproject.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

# Start and enable Gunicorn service
sudo systemctl start gunicorn
sudo systemctl enable gunicorn

# Set up Nginx configuration for Django and static file serving
sudo tee /etc/nginx/sites-available/django_project > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://unix:$PROJECT_DIR/gunicorn.sock;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /static/ {
        alias $PROJECT_DIR/static/;
    }

    location /media/ {
        alias $PROJECT_DIR/media/;
    }

    # Serve the static website content from GitHub at the root URL
    location /website/ {
        alias /var/www/html/;
        try_files \$uri \$uri/ =404;
    }
}
EOF

# Enable the Nginx configuration for Django
sudo ln -s /etc/nginx/sites-available/django_project /etc/nginx/sites-enabled
sudo nginx -t
sudo systemctl restart nginx

# Configure firewall to allow HTTP traffic (Port 80)
sudo ufw allow 'Nginx Full'

# Optional: Set up Google Cloud Storage credentials for uploading files
export GOOGLE_APPLICATION_CREDENTIALS=$SERVICE_ACCOUNT_JSON
