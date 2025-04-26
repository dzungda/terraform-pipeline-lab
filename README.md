# Deploying a 3-Tier Architecture in AWS using Terraform

<p align="center">
<img src="images/3-tier-archi.jpg" alt="image" style="width:600px;"/>
</p>

## Introduction

In this project, we will use Terraform to create a 3-tier architecture in AWS. This architecture is designed to provide scalability and reliability to the application. It divides the application into three layers: the presentation layer, the application layer, and the data layer.

1. The presentation layer, also known as the web tier, is the topmost layer of the architecture. This layer handles user requests and displays information through web browsers, mobile apps, or desktop clients.

2. The application layer, also known as the app tier. This layer acts as a bridge between the presentation layer and the data layer, ensuring proper handling of user requests and data flow.

3. The data layer, also known as the database tier. This layer processes requests from the application layer and provides the necessary information to fulfill user needs.

Terraform is an open-source tool that automates the provisioning and management of AWS infrastructure resources, making it easy to define and track desired configurations. With Terraform, you can effortlessly scale and modify AWS resources while ensuring consistent deployments and efficient collaboration.

<br/>

## Terraform Configuration Files

1. **provider.tf**: This file contains the provider definition (AWS) and the region(us-east-1) for the architecture setup.

2. **vpc.tf**: This file contains the network configuration code for VPC, NAT gateway, Elastic IP, internet gateway, and route tables for private and public subnets.
    * 2 public subnets for the web tier
    * 2 private subnets for the app tier
    * 2 private subnets for the database tier

3. **webtier.tf**: This file contains the configuration code for setting up the Web Tier.

    * Security group for the load balancer and web server
    * Internet-facing application load balancer
    * Listener group
    * Target group
    * Auto-scaling groups
    * Launch template

4. **bastionhost.tf**: This file contains the configuration code for setting up the bastion host to connect to the App Tier server.

5. **apptier.tf**: This file contains the configuration code for setting up the App Tier.

    * Security group for the load balancer and app server
    * Internal application load balancer
    * Listener group
    * Target group
    * Auto-scaling groups
    * Launch template

6. **database.tf**: This file contains the configuration code for setting up the Data Tier.

    * Security group for Aurora database
    * Subnet group for the database
    * RDS cluster

7. **variable.tf**: This file contains the variable definitions for the project.

8. **output.tf**: This file contains the output definitions for the project. Outputs allow us to retrieve information about the resources created by our configuration file.

9. **keypair.tf**: This file contains the configuration code to generate a keypair.

10. **install_apache_web.sh**: This script contains commands to set up HTTPD and install stress for testing.

11. **install_db_app.sh**: This script contains commands to set up HTTPD and install the database server for testing.

<br/>

## Deploying the 3-Tier Infrastructure in AWS

Prerequisites:
To successfully complete this project, you will need the following:
1. AWS CLI configured with your AWS account credentials.
2. Terraform installed.
3. PuTTY installed (For Windows user).
4. A text editor (e.g. Visual Studio Code).

### Cloning from the repository

Open Git Bash and change the current working directory to the location where you want the cloned directory to be.
```
cd '/c/Users/YOUR USERNAME HERE/YOUR FOLDER HERE'
git clone https
```

### Deploying the infrastructure using terraform

```
terraform init  # Intialises provider plugin and modules
terraform plan  # Create the execution plan for the code
terraform apply # Creates the infrastructure
```
Enter the username and password for your database when the system prompts you. Please remember it, as you will need it to access your database. The deployment should complete within 30mins.

<br/>

## AWS Resources Deployed

### Terraform Output

After the Terraform deployment, the following outputs should be available: the Elastic IP address, the Application load balancer(ALB) DNS name, the database endpoint, and the public IP address for the bastion host.

<img src="images/resources/terraform_output.PNG" alt="image" style="width:600px;"/>

### AWS Resources

Go to your AWS console, and it should show the following: 

**VPC**

2x public subnets for the web tier, 2x private subnets for the app tier, and 2x private subnets for the database tier. 
The web tier subnets will be connected to the internet gateway, while the app tier and database tier will be connected to the NAT gateway.

<img src="images/resources/vpc.png" alt="image" style="width:600px;"/>
<img src="images/resources/vpc_resourcemap.png" alt="image" style="width:600px;"/>
<img src="images/resources/vpc_subnet.png" alt="image" style="width:600px;"/>

**EC2**

2x EC2 instance for web tier, 2x EC2 instances for app tier 1x EC2 instance for bastion host

<img src="images/resources/ec2.png" alt="image" style="width:800px;"/>

Security Group

<img src="images/resources/security_group.png" alt="image" style="width:600px;"/>

Application Load Balancer

<img src="images/resources/load_balancer.png" alt="image" style="width:600px;"/>

Autoscaling Group

<img src="images/resources/auto_scaling_group.png" alt="image" style="width:600px;"/>

**RDS**

Aurora database that consist of a writer and a reader database

<img src="images/resources/database.png" alt="image" style="width:600px;"/>

**CloudWatch**

<img src="images/resources/cloudwatch.png" alt="image" style="width:600px;"/>

<br/>

## Putting AWS 3-Tier Architecture to the Test

**Verifying the web tier load balancer**

Verify that the web tier instances and load balancer are operational.
Enter the web tier ALB DNS name into your internet browser, click refresh, and observe the IP address change.

<img src="images/testing/1_webtier1.png" alt="image" style="width:600px;"/>
<img src="images/testing/1_webtier2.png" alt="image" style="width:600px;"/>

<br/>

**Testing the autoscaling function using stress**

Convert the generated key pair to a ppk file and ssh into the webtier EC2 instance. Normally, SSH permissions are not enabled or are restricted to specific IP addresses. However, for this stress testing, we have allowed SSH access from everywhere for easy testing.

Convert the keypair generated into a ppk file using PuTTYgen

<img src="images/testing/2_convert_ppk.png" alt="image" style="width:400px;"/>

Using PuTTY, upload the keypair.ppk file under "Credentials'" and SSH into the web tier instance.

<img src="images/testing/2_stress_ssh_config.PNG" alt="image" style="width:400px;"/>
<img src="images/testing/2_stress_ssh.PNG" alt="image" style="width:400px;"/>

After connecting, run the stress command, and you should see the CloudWatch alarm triggered, resulting in the spinning up of an additional EC2 instance.

```
sudo stress --cpu 50 --timeout 500
```
<img src="images/testing/2_stress_run.PNG" alt="image" style="width:600px;"/>

Head to the EC2 page, and you should see the auto-scaling group launch an additional EC2 instance.

<img src="images/testing/2_additonal_ec2.PNG" alt="image" style="width:600px;"/>

<br/>

**Connecting to bastion host to access app tier**

Check if the bastion host can access the app tier (For easy testing, we have allowed access from everywhere).

Using the Windows command prompt, copy the keypair to the bastion host. 

```
pscp -i C:\Users\<YOUR FILE LOCATON>\P1_3tier_archi_keypair.ppk C:\Users\<YOUR FILE LOCATON>\P1_3tier_archi_keypair ec2-user@ <BASTION HOST IP ADDRESS>:
```
<img src="images/testing/3_copy_keypair.PNG" alt="image" style="width:600px;"/>

SSH into the bastion host using PuTTY (with keypair) and check that the keypair has been copied over.

<img src="images/testing/3_ssh_bastion.PNG" alt="image" style="width:400px;"/>

Once in the bastion host, check that the keypair is copied over and change the access permission to 400.
```
chmod 400 P1_3tier_archi_keypair
ll # To check the access permission
```
<img src="images/testing/3_chmod.PNG" alt="image" style="width:600px;"/>

SSH into the app tier EC2.
```
ssh -i P1_3tier_archi_keypair ec2-user@<YOUR APP TIER EC2 IP ADDRESS>
```
<img src="images/testing/3_ssh_to_app.PNG" alt="image" style="width:600px;"/>

<br/>

**Verifying the database connectivity**

While in the app tier EC2, enter the following command to access the database. Key in your password when prompted.

```
mysql -h <DATABASE ENDPOINT> -u <DATABASE USERNAME> -p
```

<img src="images/testing/4_connectingtodb.PNG" alt="image" style="width:600px;"/>

You should be able to access the database, see the image below.

<img src="images/testing/4_connectingtodb2.PNG" alt="image" style="width:600px;"/>

<br/>

**Verifying the database failover function**

Head to the RDS service in the AWS console. Click on "Action" and select "Failover"

<img src="images/testing/5_failover1.PNG" alt="image" style="width:600px;"/>

Allow the database to failover and observe that the writer and reader databases have changed.

<img src="images/testing/5_failover2.PNG" alt="image" style="width:600px;"/>

<br/>

## Deleting the infrastructure
Remember to delete your AWS resources after you are done.
```
# Remove all the resources using terraform destroy
terraform destroy 
```