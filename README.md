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


 ##  Step 1: Setup Jenkins
<img src=""/>

<br/>  We will <br/>
<br/> We will <br/> 
<br/>  <br/>

<img src=""/>

