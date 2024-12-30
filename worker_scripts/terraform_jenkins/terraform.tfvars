bucket_name = "dev-proj-1-jenkins-remote-state-bucket-123456"

vpc_cidr             = "11.0.0.0/16"
vpc_name             = "dev-proj-jenkins-us-east-vpc-1"
cidr_public_subnet   = ["11.0.1.0/24", "11.0.2.0/24"]
cidr_private_subnet  = ["11.0.3.0/24", "11.0.4.0/24"]
us_availability_zone = ["us-east-1a", "us-east-1b"]

public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDgudaVCTqVBJnUc3RI15DKqI0Cjt31xHwtuP2DIhVVaUV1AiWXW7Vu2GI3hhB6O3M8wGdhOJYGuCSIql155r5qq0LgQ+7ACmx9QCc9LB2blBu7zrMQ2RlxbKtg+CDAigRQ9/qRfSNs0nTN92jmgnBNajYmwmVh656v9UKOZ6sfDFH/X1IsxA9ZNjyVglgBkRa+6F9lom+xUpHgzg0/+tVS15QrJ1Wbp/UHk4+CeDMKF4nxQ1wWCDRnJF+NGh75NxVn+jWUvorlJNfMd5mYUN8my3QCCWYTazJAGrXGWrZeKX3BamUtflq8S6qY1iyVpTHGs174UXhDtP9td/c8bCL7"
ec2_ami_id = "ami-0694d931cee176e7d"
