<table>
  <tr>
    <td><h1>Terraform-Jenkins-AWS-REST-API-Deployment</h1></td>
    <td>
      <p align="right">
        <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/terraform/terraform-original.svg" alt="terraform" width="60" height="60"/> 
        <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/jenkins/jenkins-original.svg" alt="jenkins" width="60" height="60"/> 
        <img src="https://raw.githubusercontent.com/Thomas-George-T/Thomas-George-T/master/assets/aws.svg" alt="aws" width="60" height="60"/> 
        <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/python/python-original.svg" alt="python" width="60" height="60"/> 
      </p>
    </td>
  </tr>
</table>






<h2>Description</h2>
<br/> 
In this project, we deploy a Python Flask application with REST API methods (GET, POST, DELETE, PATCH) to AWS. The infrastructure, including VPCs, subnets, RDS, and Elastic Load Balancers, is provisioned using Terraform. Deployment is automated through a Jenkins CI/CD pipeline, ensuring seamless integration and delivery.
<br />
<br/> Project Architecture: <br/>
<img src="https://github.com/user-attachments/assets/ad57931b-fdca-4f68-b35b-3f54590e05d1"/>
<br/> In this project, we will deploy a Python Flask REST API on AWS using Terraform for infrastructure provisioning and Jenkins for automation. <br/> 
<br/> The GitHub repository contains the application code, Terraform scripts, and a Jenkinsfile that automates the creation of AWS resources, including a VPC, subnets, an Application Load Balancer (ALB), EC2 instances, and an RDS database. <br/> <br/> Jenkins, hosted on an EC2 instance in the us-east-2 region, triggers the pipeline to provision infrastructure and deploy the API securely behind the ALB with optional HTTPS support. This architecture leverages public and private subnets, security groups, and a NAT gateway to ensure scalability, security, and efficient traffic routing. 

  <br/>

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

<br/> Once the necessary terraform modules, variables, and files have been correctly configured with the proper credentials ans AWS region it is now time to run terraform init. To follow along clone this repository into a local directory of choice and ensure the iam user and regions are correct. Also install the [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) to run from CLI. <br/>

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


### Step 4: Configure the main.tf files for the application

<img src="https://github.com/user-attachments/assets/93aa1d05-931e-4bba-8a21-5a2be6bf1351"/>

<br/> Now the that entire AWS network has been created it is now time to create a Jenkins CICD Pipeline in order to deploy the Python flask REST API application <br/>


<br/> Log into Jenkins (Note: if jenkins not installed on EC2 use docker) <br/>

<img src="https://github.com/user-attachments/assets/bf5b26a3-0f95-4801-b51d-b130222b3d22"/>

<br/> The way that Jenkins will be used is there will be a Jenkinsfile that will create a pipeline and the pipeline will execute the commands terraform init, plan, and apply. Once executed it will provision the entire infrastructure for the application. This includes the vpc, public and private subnets, igw, ec2 instance, REST API, and RDS to serve as a sql DB to store app data. This will create the entire Python REST API with terraform within Jenkins, streamlining the process with automation. <br/> 

<br/> The terraform files can be found worker_scripts/app_infrastructure similar to the previous terraform execution run git clone to follow along.  <br/>

```main.tf
/*module "s3" {
  source      = "./s3"
  bucket_name = var.bucket_name
  name        = var.name
  environment = var.bucket_name
}*/

module "networking" {
  source               = "./networking"
  vpc_cidr             = var.vpc_cidr
  vpc_name             = var.vpc_name
  cidr_public_subnet   = var.cidr_public_subnet
  eu_availability_zone = var.eu_availability_zone
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

module "lb_target_group" {
  source                   = "./load-balancer-target-group"
  lb_target_group_name     = "dev-proj-1-lb-target-group"
  lb_target_group_port     = 5000
  lb_target_group_protocol = "HTTP"
  vpc_id                   = module.networking.dev_proj_1_vpc_id
  ec2_instance_id          = module.ec2.dev_proj_1_ec2_instance_id
}

module "alb" {
  source                    = "./load-balancer"
  lb_name                   = "dev-proj-1-alb"
  is_external               = false
  lb_type                   = "application"
  sg_enable_ssh_https       = module.security_group.sg_ec2_sg_ssh_http_id
  subnet_ids                = tolist(module.networking.dev_proj_1_public_subnets)
  tag_name                  = "dev-proj-1-alb"
  #lb_target_group_arn       = module.lb_target_group.dev_proj_1_lb_target_group_arn
  ec2_instance_id           = module.ec2.dev_proj_1_ec2_instance_id
  lb_listner_port           = 5000
  lb_listner_protocol       = "HTTP"
  lb_listner_default_action = "forward"
  /* Commented out HTTPS configuration
  lb_https_listner_port     = 443
  lb_https_listner_protocol = "HTTPS"
  #dev_proj_1_acm_arn        = module.aws_ceritification_manager.dev_proj_1_acm_arn
  */
  lb_target_group_attachment_port = 5000
}

/* Commented out Hosted Zone and Certification Manager
module "hosted_zone" {
  source          = "./hosted-zone"
  domain_name     = var.domain_name
  aws_lb_dns_name = module.alb.aws_lb_dns_name
  aws_lb_zone_id  = module.alb.aws_lb_zone_id
}

module "aws_ceritification_manager" {
  source         = "./certificate-manager"
  domain_name    = var.domain_name
  hosted_zone_id = module.hosted_zone.hosted_zone_id
}
*/

module "rds_db_instance" {
  source               = "./rds"
  db_subnet_group_name = "dev_proj_1_rds_subnet_group"
  subnet_groups        = tolist(module.networking.dev_proj_1_public_subnets)
  rds_mysql_sg_id      = module.security_group.rds_mysql_sg_id
  mysql_db_identifier  = "mydb"
  mysql_username       = "dbuser"
  mysql_password       = "dbpassword"
  mysql_dbname         = "devprojdb"
}
```

<br/> Within this `main.tf` file the `Networking Module` establishes the foundational infrastructure by creating a VPC with assigned CIDR blocks for its IP range. It also defines public and private subnets within the VPC and specifies the availability zone for resource placement. These subnets and the VPC enable isolated and controlled networking for the application.

The `Security Group Module` configures access control by defining security groups. One security group permits SSH (port 22) and HTTP (port 80) traffic for general use, while another allows traffic specifically on port 5000 for a Python API. These security groups ensure that only authorized traffic can reach the resources in the VPC.

The `EC2 Module` provisions an EC2 instance to host an Ubuntu Linux environment. It uses a predefined AMI and sets the instance type to `t2.micro`. The instance is placed in the first public subnet, and a public key is provided for secure SSH access. Security groups are attached to the instance to enforce network rules, and a user data script is executed during initialization to install Apache.

The `Load Balancer Target Group Module` creates a target group to route HTTP traffic on port 5000 to the EC2 instance. This target group ensures that incoming requests are forwarded correctly within the VPC.

The `Application Load Balancer (ALB) Module` sets up a load balancer to distribute traffic. It is configured as an internal application load balancer, attached to the public subnets, and secured with the appropriate security groups. The ALB listens on port 5000 (HTTP) and forwards traffic to the target group, which directs it to the EC2 instance. Configuration for HTTPS and certificate management is commented out, as these are not required for the current project.

The `RDS Database Module` provisions a MySQL database instance for the application. The database is placed within a private subnet, ensuring its security. A NAT gateway is configured to allow the database to communicate with the EC2 instance hosting the Python Flask application, which resides in the public subnet. The module also attaches a security group to control access and configures the database with a name, username, and password. This setup ensures the database is securely integrated within the infrastructure. <br/>
<br/> Also The `Certificate Manager and Domain Modules` are commented out in the `main.tf` file because they are optional for this project. These modules would be used to manage SSL certificates and set up a custom domain through Route 53, but they are not required for the current infrastructure. They can be enabled if needed for secure HTTPS access and custom domain configurations. <br/>




## Step 5: Create the Jenkins CI/CD Pipeline 

<br/> Before creating the CICD Pipline we must add a plugin so that jenkins will be able to use our AWS credentials. Navigate to manage jenkins --> plugins --> AWS steps <br/>

<img src="https://github.com/user-attachments/assets/3ca3fae8-71a5-4c57-82aa-fe528a4cdab5"/> 
<br/> Once all the plugins have been installed navigate to manage Jenkins and credentials. Next click on System --> Global credentials --> click add. From here select the option for AWS credentials:   <br/>

<img src="https://github.com/user-attachments/assets/2f4aa47a-7e1c-4073-b42b-824226bfa816"/>
<br/> For the ID select the user you would like to use within the Jenkinsfile under worker_scripts in this respository. Next fill out the users access key ID and secret access key from AWS. <br/>
<img src="https://github.com/user-attachments/assets/276617ba-c5fb-460f-9695-68dc73e7c69a"/>

<br/> Next choose create and go to the home page. Select new item and choose Pipline <br/>

<img src="https://github.com/user-attachments/assets/f13dff6e-af65-4db0-95d3-ee1fbcb4eff5"/>

<br/> Next we will enter the Jenkinsfile <br/> 

```Groovy
pipeline {
    agent any

    parameters {
            booleanParam(name: 'PLAN_TERRAFORM', defaultValue: false, description: 'Check to plan Terraform changes')
            booleanParam(name: 'APPLY_TERRAFORM', defaultValue: false, description: 'Check to apply Terraform changes')
            booleanParam(name: 'DESTROY_TERRAFORM', defaultValue: false, description: 'Check to apply Terraform changes')
    }

    stages {
        stage('Clone Repository') {
            steps {
                // Clean workspace before cloning (optional)
                deleteDir()

                // Clone the Git repository
                git branch: 'main',
                    url: 'https://github.com/DevinLiggins14/Terraform-Jenkins-AWS-REST-API-Deployment.git'

                // Change directory to /worker_scripts/app_infrastructure
                dir('/worker_scripts/app_infrastructure') {
                    sh "ls -lart"
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials-demo-user']]) {
                    dir('/worker_scripts/app_infrastructure') {
                        sh 'echo "=================Terraform Init=================="'
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    if (params.PLAN_TERRAFORM) {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials-demo-user']]) {
                            dir('/worker_scripts/app_infrastructure') {
                                sh 'echo "=================Terraform Plan=================="'
                                sh 'terraform plan'
                            }
                        }
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    if (params.APPLY_TERRAFORM) {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials-demo-user']]) {
                            dir('/worker_scripts/app_infrastructure') {
                                sh 'echo "=================Terraform Apply=================="'
                                sh 'terraform apply -auto-approve'
                            }
                        }
                    }
                }
            }
        }

        stage('Terraform Destroy') {
            steps {
                script {
                    if (params.DESTROY_TERRAFORM) {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials-demo-user']]) {
                            dir('/worker_scripts/app_infrastructure') {
                                sh 'echo "=================Terraform Destroy=================="'
                                sh 'terraform destroy -auto-approve'
                            }
                        }
                    }
                }
            }
        }
    }
}
```

The Jenkinsfile defines the CI/CD pipeline specifically for automating the deployment and management of the AWS-based infrastructure and the Python Flask application using Terraform. The pipeline uses the `agent any` directive, allowing it to execute on any available Jenkins agent. It includes three parameters: `PLAN_TERRAFORM`, `APPLY_TERRAFORM`, and `DESTROY_TERRAFORM`. These parameters provide control over the Terraform operations, allowing us to plan, apply, or destroy the infrastructure as needed for this project.

The pipeline begins with the **Clone Repository** stage. Here, the workspace is cleaned to ensure no residual files from previous builds. This Git repository, which contains the Terraform configurations and application code, is cloned from the URL. The working directory is then changed to `/worker_scripts/app_infrastructure` to focus on the relevant infrastructure scripts for deploying the Python Flask API and AWS resources. This ensures that all subsequent stages operate within the correct context.

In the **Terraform Init** stage, the pipeline securely injects AWS credentials we defined using the `withCredentials` block, referencing the `aws-credentials-demo-user`. This step initializes the Terraform configuration located in the `app_infrastructure` directory, preparing it to manage the project's AWS infrastructure. Initialization ensures that Terraform can interact with the AWS backend and state files, which are stored in the S3 bucket named `terraform-backend6`.

The **Terraform Plan** stage checks if the `PLAN_TERRAFORM` parameter is enabled. If true, the pipeline injects AWS credentials securely and runs the `terraform plan` command within the `app_infrastructure` directory. This step generates an execution plan that details the changes Terraform will make to the AWS infrastructure. For this project, the plan outlines the creation or modification of resources such as the VPC, subnets, security groups, EC2 instance, load balancer, and RDS database, all of which are crucial for deploying the Python Flask API.

In the **Terraform Apply** stage, the pipeline checks if the `APPLY_TERRAFORM` parameter is true. When enabled, AWS credentials are injected, and the `terraform apply -auto-approve` command is executed in the `app_infrastructure` directory. This command applies the infrastructure changes defined in the Terraform configuration. Specifically, it provisions the AWS resources, such as the EC2 instance running the Flask application, the ALB routing traffic to the target group, and the RDS database securely hosted in the private subnet.

The **Terraform Destroy** stage runs if the `DESTROY_TERRAFORM` parameter is true. AWS credentials are securely injected, and the `terraform destroy -auto-approve` command is executed. This stage removes all AWS resources created by the Terraform configuration, ensuring a complete teardown of the project's infrastructure. This is particularly useful for cleaning up after testing or decommissioning the deployment.

This Jenkinsfile is a critical component of the project, enabling automated and secure deployment of the AWS infrastructure and Python Flask application. By integrating Terraform with Jenkins, it ensures a streamlined process for managing the project's resources. Sensitive information, such as AWS credentials, is handled securely, and the use of parameters allows for flexible execution of Terraform commands based on the project's requirements.

<br/> In Jenkins select repository from SCM and paste this repositories URL. No credentials since this repo is public and choose main branch. Leave the script path as `worker_scripts/Jenkinsfile` since it will be available right away <br/>

<img src="https://github.com/user-attachments/assets/a5196fa4-a395-42d2-b3f2-124684c9911f"/>

## Step 6: Deploy

<br/> All that's left is to select the newly created pipline and click `build now` <br/>


<br/> Note: while troubleshooting this Jenkinsfile I had to remove the ls command after cloning the repository due to permissions and also using the jenkins workspace instead of `worker_scripts` because it was being misinterpreted to be local. This all resulted in an incomplete pipline:   <br/>

<img src="https://github.com/user-attachments/assets/a8fe6971-365d-4085-8673-1a427d1188b7"/>
<img src="https://github.com/user-attachments/assets/80a604da-ff8b-4e77-83a6-428d07ede8eb"/>

<br/> Upon inspecting the logs I can see terraform is not installed so I will install it using the global configuration tool <br/>

<br/> I first had to install a terraform plugin then go to manage jenkins --> tools --> add terraform (select the correct Linux version) <br/>

<img src="https://github.com/user-attachments/assets/b9dffb2b-0ec3-4254-bfe0-d3f206750e7e"/>

<br/> The output was sucessful! <br/>

https://github.com/user-attachments/assets/d2decf02-7a1a-432f-a8c1-01063ad82d69

<img src="https://github.com/user-attachments/assets/953e8293-0fc1-4498-8899-6ba4b2376065"/>
<img src="https://github.com/user-attachments/assets/9980e934-7096-47fa-8514-68e18e2e46c3"/>

<br/> Now I can fully manage the applkication deployment from Jenkins successfully, fully automating the process <br/>




<img src="https://github.com/user-attachments/assets/36f3703e-e22a-4b23-829c-c10782492193"/>

<br/> Now that the terraform files have been initalized now I can go step by step to plan, apply, and destroy the deployment <br/> 

<img src="https://github.com/user-attachments/assets/2eb8b237-398b-4e91-958b-254c21be08f0"/>

<br/> Troubleshooting each step of the way for the deployment. (Fixing variables .tf file mismatch) <br/>
<img src="https://github.com/user-attachments/assets/4bcbd1a3-928b-47e3-8393-a5ae387b94ab"/>


<img src=""/>


<img src=""/>


<img src=""/>


<img src=""/>


<img src=""/>
