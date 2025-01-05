module "networking" {
  source               = "./networking"
  vpc_cidr             = var.vpc_cidr
  vpc_name             = var.vpc_name
  cidr_public_subnet   = var.cidr_public_subnet
  us_availability_zone = var.us_availability_zone
  cidr_private_subnet  = var.cidr_private_subnet
}

module "security_group" {
  source                     = "./security-groups"
  ec2_sg_name                = "SG for EC2 to enable SSH(22) and HTTP(80)"
  vpc_id                     = module.networking.dev_proj_1_vpc_id
  public_subnet_cidr_block   = tolist(module.networking.public_subnet_cidr_block)
  ec2_sg_name_for_python_api = "SG for EC2 for enabling port 5000"
}

module "ec2" {
  source                   = "./ec2"
  ami_id                   = var.ec2_ami_id
  instance_type            = "t2.micro"
  tag_name                 = "Ubuntu Linux EC2"
  public_key               = var.public_key
  subnet_id                = tolist(module.networking.dev_proj_1_public_subnets)[0]
  sg_enable_ssh_https      = module.security_group.sg_ec2_sg_ssh_http_id
  ec2_sg_name_for_python_api = module.security_group.sg_ec2_for_python_api
  enable_public_ip_address = true
  user_data_install_apache = templatefile("./template/ec2_install_apache.sh", {})
}

module "load_balancer_target_group" {
  source               = "./load-balancer-target-group"  # Corrected to relative path
  lb_target_group_arn  = var.lb_target_group_arn
  ec2_instance_id      = module.ec2.dev_proj_1_ec2_instance_id
  lb_target_group_port = 5000
}

module "alb" {
  source                    = "./load-balancer"
  lb_name                   = "dev-proj-1-alb"
  is_external               = false
  lb_type                   = "application"
  sg_enable_ssh_https       = module.security_group.sg_ec2_sg_ssh_http_id
  subnet_ids                = tolist(module.networking.dev_proj_1_public_subnets)
  tag_name                  = "dev-proj-1-alb"
  lb_target_group_arn       = module.load_balancer_target_group.dev_proj_1_lb_target_group_arn
  ec2_instance_id           = module.ec2.dev_proj_1_ec2_instance_id
  lb_listner_port           = 5000
  lb_listner_protocol       = "HTTP"
  lb_listner_default_action = "forward"
  lb_target_group_attachment_port = 5000
}

variable "lb_target_group_arn" {
  type        = string
  description = "ARN of the load balancer target group"
}

variable "ec2_ami_id" {
  type        = string
  description = "AMI ID for the EC2 instance"
}

variable "public_key" {
  type        = string
  description = "Public key for EC2 instance"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "vpc_name" {
  type        = string
  description = "Name for the VPC"
}

variable "cidr_public_subnet" {
  type        = list(string)
  description = "CIDR blocks for public subnets"
}

variable "us_availability_zone" {
  type        = list(string)
  description = "Availability zones for the VPC"
}

variable "cidr_private_subnet" {
  type        = list(string)
  description = "CIDR blocks for private subnets"
}
