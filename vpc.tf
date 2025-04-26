#Creating a new VPC
resource "aws_vpc" "P1-3-tier-archi" {
 cidr_block           = var.vpc_cidr
 enable_dns_hostnames = true
 
 tags = {
   Name = "P1-3-tier-archi"
 }
}

#Creating a public subnet for web tier
resource "aws_subnet" "public_webtier_subnet" {
  count             = length(var.public_webtier_subnet_cidrs) 
  vpc_id            = aws_vpc.P1-3-tier-archi.id
  cidr_block        = element(var.public_webtier_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "Public Webtier Subnet ${count.index + 1}"
  }
}

#Creating a private subnet for app tier
resource "aws_subnet" "private_apptier_subnet" {
  count             = length(var.private_apptier_subnet_cidrs) 
  vpc_id            = aws_vpc.P1-3-tier-archi.id
  cidr_block        = element(var.private_apptier_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "Private Apptier Subnet ${count.index + 1}"
  }
}

#Creating a private subnet for database tier
resource "aws_subnet" "private_database_subnet" {
  count             = length(var.private_database_subnet_cidrs) 
  vpc_id            = aws_vpc.P1-3-tier-archi.id
  cidr_block        = element(var.private_database_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "Private Database Subnet ${count.index + 1}"
  }
}

#Creating a internet gateway for our VPC
resource "aws_internet_gateway" "P1_IG" {
 vpc_id = aws_vpc.P1-3-tier-archi.id
 
 tags = {
   Name = "P1_internet_gateway"
 }
}

#Create a new public route table for the public subnet 
resource "aws_route_table" "public_RT" {
 vpc_id = aws_vpc.P1-3-tier-archi.id

 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.P1_IG.id
 }
 
 tags = {
   Name = "Public Route Table"
 }
}

#Associate the public subnet to the public route table
resource "aws_route_table_association" "public_subnet_asso" {
  count          = length(var.public_webtier_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_webtier_subnet[*].id, count.index)
  route_table_id = aws_route_table.public_RT.id
}

# Creating an Elastic IP for the NAT Gateway
resource "aws_eip" "NAT-Gateway-EIP" {
  depends_on = [
    aws_route_table_association.public_subnet_asso
  ]
  vpc = true
}

# Creating a NAT Gateway
resource "aws_nat_gateway" "Private_NAT_GW" {
  depends_on = [
    aws_internet_gateway.P1_IG
  ]

  # Allocating the Elastic IP to the NAT Gateway
  allocation_id = aws_eip.NAT-Gateway-EIP.id
  
  # Associating it in the Public Subnet
  subnet_id = element(aws_subnet.public_webtier_subnet[*].id, 1) 
  tags = {
    Name = "P1_NAT_Gateway" 
  }
}

# Creating a Route Table for the Nat Gateway
resource "aws_route_table" "NAT-Gateway-RT-Apptier" {
  depends_on = [
    aws_nat_gateway.Private_NAT_GW
  ]

  vpc_id = aws_vpc.P1-3-tier-archi.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.Private_NAT_GW.id
  }

  tags = {
    Name = "Route Table for NAT Gateway App tier"
  }
}


# Creating a Route Table for the Nat Gateway
resource "aws_route_table" "NAT-Gateway-RT-Database" {
  depends_on = [
    aws_nat_gateway.Private_NAT_GW
  ]

  vpc_id = aws_vpc.P1-3-tier-archi.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.Private_NAT_GW.id
  }

  tags = {
    Name = "Route Table for NAT Gateway Database"
  }

}

# Creating an Route Table Association for App tier to NAT GAteway 
resource "aws_route_table_association" "Nat-Gateway-RT-Association-Apptier" {
  depends_on = [
    aws_route_table.NAT-Gateway-RT-Apptier
  ]

  count     = length(var.private_apptier_subnet_cidrs)
  subnet_id = element(aws_subnet.private_apptier_subnet[*].id, count.index)

  route_table_id = aws_route_table.NAT-Gateway-RT-Apptier.id
}

# Creating an Route Table Association for Database tier to NAT GAteway 
resource "aws_route_table_association" "Nat-Gateway-RT-Association-Database" {
  depends_on = [
    aws_route_table.NAT-Gateway-RT-Database
  ]
  count     = length(var.private_database_subnet_cidrs)
  subnet_id = element(aws_subnet.private_database_subnet[*].id, count.index) 

  route_table_id = aws_route_table.NAT-Gateway-RT-Database.id
}
