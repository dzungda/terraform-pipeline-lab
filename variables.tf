variable "vpc_cidr" {
 type        = string
 description = "VPC CIDR value"
 default     = "10.0.0.0/16"
}

variable "public_webtier_subnet_cidrs" {
 type        = list(string)
 description = "Public Subnet CIDR values"
 default     = ["10.0.1.0/24", "10.0.2.0/24"]
}
 
variable "private_apptier_subnet_cidrs" {
 type        = list(string)
 description = "Private Subnet CIDR values"
 default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "private_database_subnet_cidrs" {
 type        = list(string)
 description = "Private Subnet CIDR values"
 default     = ["10.0.5.0/24", "10.0.6.0/24"]
}

variable "azs" {
 type        = list(string)
 description = "Availability Zones"
 default     = ["us-east-1a", "us-east-1b"]
}

variable "amis" {
  type        = string
  description = "Instance AMI"
  default     = "ami-02396cdd13e9a1257"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}
