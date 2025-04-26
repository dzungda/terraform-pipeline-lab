# Create Bastion Host Security Group
resource "aws_security_group" "bastion-host-sg" {
  name        = "Bastion-SG"
  description = "Allow Bastion host to ssh to App tier"
  vpc_id      = aws_vpc.P1-3-tier-archi.id

  # For security reasons, bastion host should only allow from specific IP address. But for the ease of testing, we have allow ssh from anywhere
  ingress {
    description = "ssh from anywhere "
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }    

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Bastion-SG"
  }
}


# Create Bastion Host instance
resource "aws_instance" "bastion-host" {
    ami                         = var.amis
    associate_public_ip_address = true
    instance_type               = var.instance_type
    key_name                    = aws_key_pair.P1_3tier_archi_keypair.key_name
    security_groups             = [aws_security_group.bastion-host-sg.id]
    subnet_id                   = element(aws_subnet.public_webtier_subnet[*].id, 0) 
    
    tags = {
      Name = "Bastion Host"
    }
}
