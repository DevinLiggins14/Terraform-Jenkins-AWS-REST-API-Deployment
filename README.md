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


<br/> Within this main.tf file the Networking Module establishes the foundational infrastructure by creating a VPC with assigned CIDR blocks for its IP range. It also defines public and private subnets within the VPC and specifies the availability zone for resource placement. These subnets and the VPC enable isolated and controlled networking for the application.

The Security Group Module configures access control by defining security groups. One security group permits SSH (port 22), HTTP (port 80), and HTTPS (port 443) traffic for general use, while another allows traffic specifically on port 8080 for Jenkins. These security groups ensure that only authorized traffic can reach the resources in the VPC.

The Jenkins Module provisions an EC2 instance to host Jenkins. It uses a predefined AMI and sets the instance type to t2.medium. The instance is placed in the first public subnet, and a public key is provided for secure SSH access. Security groups are attached to the instance to enforce network rules, and a user data script is executed during initialization to automatically install Jenkins.

The Load Balancer Target Group Module creates a target group to route HTTP traffic on port 8080 to the Jenkins EC2 instance. This target group ensures that incoming requests are forwarded correctly within the VPC.

The Application Load Balancer (ALB) Module sets up a load balancer to distribute traffic. It is configured as an internal application load balancer, attached to the public subnets, and secured with the appropriate security groups. The ALB listens on ports 80 (HTTP) and 443 (HTTPS), forwarding traffic to the target group, which directs it to the Jenkins instance.  <br/>

<img src=""/>

