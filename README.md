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


 ##  Step 1: Configure Terraform 
<img src="https://github.com/user-attachments/assets/ea91aad3-2a94-41b0-9474-426ca7cefde3"/>

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
  source              = "./security_groups"
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
  user_data_install_jenkins = templatefile("./jenkins_runner_script/jenkins_installer.sh", {})
}

module "lb_target_group" {
  source                   = "./lb_target_group"
  lb_target_group_name     = "jenkins-lb-target-group"
  lb_target_group_port     = 8080
  lb_target_group_protocol = "HTTP"
  vpc_id                   = module.networking.dev_proj_1_vpc_id
  ec2_instance_id          = module.jenkins.jenkins_ec2_instance_ip
}

module "alb" {
  source                    = "./alb"
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
  # dev_proj_1_acm_arn        = module.aws_ceritification_manager.dev_proj_1_acm_arn
  lb_target_group_attachment_port = 8080
}

/*module "hosted_zone" {
  source          = "./hosted-zone"
  domain_name     = "Domain of choice"
  aws_lb_dns_name = module.alb.aws_lb_dns_name
  aws_lb_zone_id  = module.alb.aws_lb_zone_id
}
*/
/*module "aws_ceritification_manager" {
  source         = "./certificate-manager"
  domain_name    = "Domain of choice"
  hosted_zone_id = module.hosted_zone.hosted_zone_id
}
*/
```

<br/> Within this main.tf file the `Networking Module` establishes the foundational infrastructure by creating a VPC with assigned CIDR blocks for its IP range. It also defines public and private subnets within the VPC and specifies the availability zone for resource placement. These subnets and the VPC enable isolated and controlled networking for the application.

The `Security Group Module` configures access control by defining security groups. One security group permits SSH (port 22), HTTP (port 80), and HTTPS (port 443) traffic for general use, while another allows traffic specifically on port 8080 for Jenkins. These security groups ensure that only authorized traffic can reach the resources in the VPC.

The `Jenkins Module` provisions an EC2 instance to host Jenkins. It uses a predefined AMI and sets the instance type to t2.medium. The instance is placed in the first public subnet, and a public key is provided for secure SSH access. Security groups are attached to the instance to enforce network rules, and a user data script is executed during initialization to automatically install Jenkins.

The `Load Balancer Target Group Module` creates a target group to route HTTP traffic on port 8080 to the Jenkins EC2 instance. This target group ensures that incoming requests are forwarded correctly within the VPC.

The `Application Load Balancer (ALB) Module` sets up a load balancer to distribute traffic. It is configured as an internal application load balancer, attached to the public subnets, and secured with the appropriate security groups. The ALB listens on ports 80 (HTTP) and 443 (HTTPS), forwarding traffic to the target group, which directs it to the Jenkins instance.  <br/>


<br/> Also The `Certificate Manager and Domain modules` are commented out in the main.tf file because they are optional for this project. These modules would be used to manage SSL certificates and set up a custom domain through Route 53, but they are not required for the core Jenkins deployment. They can be enabled if needed for secure HTTPS access and custom domain configurations.

<br/> 

## Step 2: Initalize Terraform

<br/> Once the necessary terraform modules, variables, and files have been correctly configured with the proper credentials ans AWS region it is now time to run terraform init. To follow along clone this repository into a local directory of choice and ensure the aws-key pair, iam user, and regions are correct. Also install the [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) to run from CLI. <br/>

<img src="https://github.com/user-attachments/assets/e1e3350f-8678-42e1-8003-591446fbf543"/>


<br/> For this project I am also using an S3 bucket for the terraform backend to store data. The S3 bucket provides a centralized, remote location for managing infrastructure state, enabling collaboration among team members and ensuring consistency. <br/> 

## Step 3: Create the AWS infrastucture 

<br/> Now I will run `terraform apply --auto-approve` in order to automate the deployment of all the AWS resources. Afterwards the next step will be to create and configure a Jenkins CICD pipline to deploy the python flask application   <br/>

<img src="https://github.com/user-attachments/assets/08c3527f-0275-4ca9-ad1b-b72a86edaeaf"/> 

<br/> quick error, this stem from the fact that the `us_availability_zone` variable was not declared in my variables.tf file but one for an eu region instead which is why it is important to confirm all file confiurations prior to applying changes. While troubleshooting I also had fixed the jenkins main.tf ec2 connection path, the jenkins_install.sh path in main.tf, and the certificate module in main.tf <br/>
<br/> Now I will run the command again <br/>



https://github.com/user-attachments/assets/215aba3d-8c66-46ea-a2ab-5acddfc0d279




<br/> Now the AWS resources should be available within the AWS console: <br/> 

<img src="https://github.com/user-attachments/assets/fd01d773-0165-44a7-88e1-df03a268deeb"/>
<img src="https://github.com/user-attachments/assets/52b2329b-da8e-47c3-b6f0-48146f548fae"/>
<img src="https://github.com/user-attachments/assets/13bc4a0d-1086-46fa-8801-194eecfa3c06"/>
<img src="https://github.com/user-attachments/assets/c1d1112d-ebd9-4ba8-9e5c-4eb11cb708dd"/>
<img src="https://github.com/user-attachments/assets/1f4b157f-50a2-4999-ac83-f456885225a6"/>


### Step 4: Create Jenkins CICD Pipeline

<img src="https://github.com/user-attachments/assets/93aa1d05-931e-4bba-8a21-5a2be6bf1351"/>

<br/> Now the that entire AWS network has been created it is now time to create a Jenkins CICD Pipeline in order to deploy the Python flask REST API application <br/>


<br/> Log into Jenkins (Note: if jenkins not installed on EC2 use docker) <br/>

<img src="https://github.com/user-attachments/assets/bf5b26a3-0f95-4801-b51d-b130222b3d22"/>

<br/> The way that Jenkins will be used is there will be a Jenkinsfile that will create a pipeline and the pipeline will execute the commands terraform init, plan, and apply. Once executed it will provision the entire infrastructure for the application. This includes the vpc, public and private subnets, igw, ec2 instance and REST API, and RDS to serve as a sql db to store app data. This will create the entire Python REST API within terraform within Jenkins, streamlining the process with automation. <br/> 

<br/> The terraform files can be found worker_scripts/app_infrastructure similar to the previous terraform execution run git clone to follow along.  <br/>



<img src=""/>

<br/>  <br/>


## Step :

<br/>  <br/>

<img src=""/> 
<br/> <br/>

## Step :

<br/>  <br/>

<img src=""/> 
<br/> <br/>

## Step :

<br/>  <br/>

<img src=""/> 
<br/> <br/>

