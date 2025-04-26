#!/bin/bash

#Change to root user
sudo su

#Update all package repositories
dnf update -y

#Install mariadb on instance
dnf install mariadb105-server -y

#Install apache for ALB listener
dnf install -y httpd
systemctl start httpd
systemctl enable httpd
touch /var/www/html/index.html

