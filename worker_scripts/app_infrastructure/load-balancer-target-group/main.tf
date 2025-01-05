module "load-balancer" {
  source                    = "./load-balancer"
  lb_name                   = "dev-proj-1-alb"
  is_external               = false
  lb_type                   = "application"
  sg_enable_ssh_https       = module.security_group.sg_ec2_sg_ssh_http_id
  subnet_ids                = tolist(module.networking.dev_proj_1_public_subnets)
  tag_name                  = "dev-proj-1-alb"
  lb_target_group_arn       = module.lb_target_group.dev_proj_1_lb_target_group_arn
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
