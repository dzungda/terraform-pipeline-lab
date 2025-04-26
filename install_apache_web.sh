#!/bin/bash

#Change to root user
sudo su

#Update all package repositories
dnf update -y

#Install Apache web server
dnf install -y httpd

#Install stress to test EC2 Instance under stress work load
dnf install stress -y

#Start and Enable Apache web server
systemctl start httpd
systemctl enable httpd

#Retrive EC2 instance public ipv4 metadata
publicipv4=$(TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` \
&& curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/public-ipv4)

# Include a simple webpage to show the IP address of the instance
echo "<html><head><style>h1 {text-align: center;}h2 {text-align: center;}</style></head><body><h1>Welcome to my Web Server! </h1><h2>IP address: $publicipv4</h2></body></html>" > /var/www/html/index.html
