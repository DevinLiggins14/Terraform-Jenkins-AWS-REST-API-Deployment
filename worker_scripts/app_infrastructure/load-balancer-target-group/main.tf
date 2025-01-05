variable "lb_target_group_arn" {}
variable "ec2_instance_id" {}
variable "lb_target_group_port" {}

resource "aws_lb_target_group" "dev_proj_1_lb_target_group" {
  name     = "dev-proj-1-lb-target-group"
  port     = var.lb_target_group_port
  protocol = "HTTP"
  vpc_id   = module.networking.dev_proj_1_vpc_id

  health_check {
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }

  tags = {
    Name = "dev-proj-1-lb-target-group"
  }
}

resource "aws_lb_target_group_attachment" "dev_proj_1_lb_target_group_attachment" {
  target_group_arn = var.lb_target_group_arn
  target_id        = var.ec2_instance_id
  port             = var.lb_target_group_port
}
