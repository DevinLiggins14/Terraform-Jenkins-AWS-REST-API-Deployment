# Terraform-Jenkins-AWS-REST-API-Deployment
<h2>Description</h2>
<br/> In this project we will deploy 

<br />
<br/> Project Architecture: <br/>
<img src=""/>
<br/> We will  <br/>

<h2> Services involved: </h2>

| **Service**           | **Purpose**                                                                 |
|------------------------|-----------------------------------------------------------------------------|
| **Jenkins**           | Implements the CI/CD pipeline to provision infrastructure and deploy the application. |
| **Terraform**         | Provisions AWS resources, including VPC, subnets, RDS, Route 53, and other networking components. |
| **VPC**               | Creates an isolated network for the application.                           |
| **Public Subnet**     | Hosts public-facing components like the Elastic Load Balancer and Flask API. |
| **Private Subnet**    | Secures sensitive resources like the RDS database.                         |
| **Elastic Load Balancer** | Distributes traffic to the Flask application running in the public subnet. |
| **RDS**               | Provides managed relational database storage for application data.         |
| **Route 53** (optional) | Manages custom domain names for the application.                         |
| **Certificate Manager** | Enables HTTPS for secure communication.                                  |



### **Notes for Usage**
1. **Required Services**: Terraform, Jenkins, VPC, subnets (public and private), Elastic Load Balancer, Route Table, Internet Gateway, Target Group, RDS, and Certificate Manager.
2. **Optional Services**: Route 53: for managing custom domain names. Certificate Manager: For enabling HTTPS (optional depending on security requirements).



<p align="center">
  
### **Prerequisites**  
- Have an [AWS account](https://aws.amazon.com/console/)
- Install [terraform](https://developer.hashicorp.com/terraform/install).  


 ##  Step 1: Setup Jenkins and AWS network
<img src="https://github.com/user-attachments/assets/3386eb7e-3373-40d7-b5e4-7fc64f9023f8"/>

<br/>  First we will use terraform to configure and create a VPC within AWS that will support and install Jenkins on an EC2 instance. <br/>
<br/> We will use the following `main.tf` file to provision a modular, secure, and scalable infrastructure on AWS for hosting Jenkins with networking, security, and load balancing configurations. <br/> 

```main.tf
module "networking" {
  source               = "./networking"
  vpc_cidr             = var.vpc_cidr
  vpc_name             = var.vpc_name
  cidr_public_subnet   = var.cidr_public_subnet
  us_availability_zone = var.us_availability_zone
  cidr_private_subnet  = var.cidr_private_subnet
}

module "security_group" {
  source              = "./security-groups"
  ec2_sg_name         = "SG for EC2 to enable SSH(22), HTTPS(443) and HTTP(80)"
  vpc_id              = module.networking.dev_proj_1_vpc_id
  ec2_jenkins_sg_name = "Allow port 8080 for Jenkins"
}

module "jenkins" {
  source                    = "./jenkins"
  ami_id                    = var.ec2_ami_id
  instance_type             = "t2.medium"
  tag_name                  = "Jenkins:Ubuntu Linux EC2"
  public_key                = var.public_key
  subnet_id                 = tolist(module.networking.dev_proj_1_public_subnets)[0]
  sg_for_jenkins            = [module.security_group.sg_ec2_sg_ssh_http_id, module.security_group.sg_ec2_jenkins_port_8080]
  enable_public_ip_address  = true
  user_data_install_jenkins = templatefile("./jenkins-runner-script/jenkins-installer.sh", {})
}

module "lb_target_group" {
  source                   = "./load-balancer-target-group"
  lb_target_group_name     = "jenkins-lb-target-group"
  lb_target_group_port     = 8080
  lb_target_group_protocol = "HTTP"
  vpc_id                   = module.networking.dev_proj_1_vpc_id
  ec2_instance_id          = module.jenkins.jenkins_ec2_instance_ip
}

module "alb" {
  source                    = "./load-balancer"
  lb_name                   = "dev-proj-1-alb"
  is_external               = false
  lb_type                   = "application"
  sg_enable_ssh_https       = module.security_group.sg_ec2_sg_ssh_http_id
  subnet_ids                = tolist(module.networking.dev_proj_1_public_subnets)
  tag_name                  = "dev-proj-1-alb"
  lb_target_group_arn       = module.lb_target_group.dev_proj_1_lb_target_group_arn
  ec2_instance_id           = module.jenkins.jenkins_ec2_instance_ip
  lb_listner_port           = 80
  lb_listner_protocol       = "HTTP"
  lb_listner_default_action = "forward"
  lb_https_listner_port     = 443
  lb_https_listner_protocol = "HTTPS"
  dev_proj_1_acm_arn        = module.aws_ceritification_manager.dev_proj_1_acm_arn
  lb_target_group_attachment_port = 8080
}

/*module "hosted_zone" {
  source          = "./hosted-zone"
  domain_name     = "Domain of choice"
  aws_lb_dns_name = module.alb.aws_lb_dns_name
  aws_lb_zone_id  = module.alb.aws_lb_zone_id
}

/*module "aws_ceritification_manager" {
  source         = "./certificate-manager"
  domain_name    = "Domain of choice"
  hosted_zone_id = module.hosted_zone.hosted_zone_id
}
```

<br/> Within this main.tf file the `Networking Module` establishes the foundational infrastructure by creating a VPC with assigned CIDR blocks for its IP range. It also defines public and private subnets within the VPC and specifies the availability zone for resource placement. These subnets and the VPC enable isolated and controlled networking for the application.

The `Security Group Module` configures access control by defining security groups. One security group permits SSH (port 22), HTTP (port 80), and HTTPS (port 443) traffic for general use, while another allows traffic specifically on port 8080 for Jenkins. These security groups ensure that only authorized traffic can reach the resources in the VPC.

The `Jenkins Module` provisions an EC2 instance to host Jenkins. It uses a predefined AMI and sets the instance type to t2.medium. The instance is placed in the first public subnet, and a public key is provided for secure SSH access. Security groups are attached to the instance to enforce network rules, and a user data script is executed during initialization to automatically install Jenkins.

The `Load Balancer Target Group Module` creates a target group to route HTTP traffic on port 8080 to the Jenkins EC2 instance. This target group ensures that incoming requests are forwarded correctly within the VPC.

The `Application Load Balancer (ALB) Module` sets up a load balancer to distribute traffic. It is configured as an internal application load balancer, attached to the public subnets, and secured with the appropriate security groups. The ALB listens on ports 80 (HTTP) and 443 (HTTPS), forwarding traffic to the target group, which directs it to the Jenkins instance.  <br/>


<br/> Also The `Certificate Manager and Domain modules` are commented out in the main.tf file because they are optional for this project. These modules would be used to manage SSL certificates and set up a custom domain through Route 53, but they are not required for the core Jenkins deployment. They can be enabled if needed for secure HTTPS access and custom domain configurations.

<br/> 




<img src=""/>


<br/> <br/> 


<br/> <br/>

<img src=""/> 
