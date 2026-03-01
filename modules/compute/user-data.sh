#!/bin/bash
set -e

yum update -y
yum install -y nginx

# Create health check endpoint
mkdir -p /usr/share/nginx/html
echo '{"status":"ok"}' > /usr/share/nginx/html/health

systemctl enable nginx
systemctl start nginx
