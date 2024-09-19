#!/bin/bash

# Update the package index
sudo apt-get update

# Install Nginx
sudo apt-get install -y nginx

# Install git
sudo apt install -y git

# Install Python3, pip, and venv
sudo apt-get install -y python3 python3-pip python3-venv

# Set up variables
GITHUB_REPO=https://github.com/varghele/FAI.git
GCP_BUCKET="fischerai-1h1hnoesy-bucket"

# Install the Google Cloud SDK and the Google Cloud Storage library
sudo apt-get install -y apt-transport-https ca-certificates gnupg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo tee /usr/share/keyrings/cloud.google.gpg
sudo apt-get update && sudo apt-get install -y google-cloud-sdk
sudo pip install google-cloud-storage

# Create a directory for the Flask app and the html
sudo mkdir -p /var/www/flaskapp
sudo mkdir -p /var/www/flaskapp/html/
sudo chown -R $USER:$USER /var/www/flaskapp

# Clone the GitHub repository and copy files to the Nginx web directory
sudo mkdir -p /tmp/website
sudo git clone $GITHUB_REPO /tmp/website
sudo cp -a /tmp/website/html/* /var/www/flaskapp/html/
# sudo mkdir -p $FLASK_APP_DIR && sudo cp -a ~/tmp/website/flask/* $FLASK_APP_DIR
# sudo cp -a ~/tmp/website/* $FLASK_APP_DIR
#sudo rm -rf /tmp/website  # Clean up the temporary directory

# Navigate to the app directory
cd /var/www/flaskapp

# Create a Python virtual environment
python3 -m venv venv

# Activate the virtual environment and install Flask, Gunicorn, and GCS library
source venv/bin/activate
pip install flask gunicorn google-cloud-storage

# Create the Flask app with file upload form and GCS integration
cat > app.py << EOF
from flask import Flask, render_template_string, render_template, request, redirect
from google.cloud import storage
import os

# Initialize Flask app
app = Flask(__name__)

# Set up Google Cloud Storage client
BUCKET_NAME = $GCP_BUCKET

def upload_to_bucket(file):
    storage_client = storage.Client()
    bucket = storage_client.get_bucket(BUCKET_NAME)
    blob = bucket.blob(file.filename)
    blob.upload_from_file(file)

@app.route('/')
def index():
    """Render the main form."""
    return render_template('html/index.html')

# Route for file upload form
#@app.route('/', methods=['GET', 'POST'])
#def upload_file():
#    if request.method == 'POST':
#        if 'file' not in request.files:
#            return "No file part"
#        file = request.files['file']
#        if file.filename == '':
#            return 'No selected file'
#        if file:
#            upload_to_bucket(file)
#            return f"File {file.filename} uploaded successfully to {BUCKET_NAME}!"
#    return '''
#        <form method="post" enctype="multipart/form-data">
#            <input type="file" name="file">
#            <input type="submit" value="Upload">
#        </form>
#    '''

if __name__ == '__main__':
    app.run(host='0.0.0.0')
EOF

# Deactivate the virtual environment
deactivate

# Create a systemd service file for Gunicorn
sudo tee /etc/systemd/system/flaskapp.service > /dev/null << EOF
[Unit]
Description=Gunicorn instance to serve flaskapp
After=network.target

[Service]
User=$USER
Group=www-data
WorkingDirectory=/var/www/flaskapp
Environment="PATH=/var/www/flaskapp/venv/bin"
ExecStart=/var/www/flaskapp/venv/bin/gunicorn --workers 3 --bind unix:/var/www/flaskapp/flaskapp.sock -m 007 app:app

[Install]
WantedBy=multi-user.target
EOF

# Start and enable the Flask app service
sudo systemctl daemon-reload
sudo systemctl start flaskapp
sudo systemctl enable flaskapp

# Configure Nginx to proxy requests to the Flask app
sudo tee /etc/nginx/sites-available/flaskapp > /dev/null << EOF
server {
    listen 80;
    server_name _;

    location / {
        include proxy_params;
        proxy_pass http://unix:/var/www/flaskapp/flaskapp.sock;
    }
}
EOF

# Enable the new Nginx server block configuration
sudo ln -sf /etc/nginx/sites-available/flaskapp /etc/nginx/sites-enabled

# Remove the default Nginx server block
sudo rm -f /etc/nginx/sites-enabled/default

# Test the Nginx configuration for syntax errors
sudo nginx -t

# Restart Nginx to apply the changes
sudo systemctl restart nginx
