#!/bin/bash

# Update package lists and install Nginx and Git
sudo apt update
sudo apt install -y nginx git

# Enable and start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Clone the GitHub repository and copy files to the Nginx web directory
GITHUB_REPO=https://github.com/varghele/FAI.git
git clone $GITHUB_REPO /tmp/website

# Copy the contents of the html directory to the Nginx web root
sudo cp -r /tmp/website/html/* /var/www/html/

# Clean up the temporary directory
sudo rm -rf /tmp/website

# Restart Nginx to serve the new content
sudo systemctl restart nginx
