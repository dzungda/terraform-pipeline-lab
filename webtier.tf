# Create Web Tier ALB Security Group
resource "aws_security_group" "webtier-alb-sg" {
  name        = "Webtier-ALB-SG"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = aws_vpc.P1-3-tier-archi.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }    

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Webtier-ALB-SG"
  }
}

# Create Web Tier Security Group
resource "aws_security_group" "webtier-sg" {
  name        = "Webtier-SG"
  description = "Allow inbound traffic from ALB"
  vpc_id      = aws_vpc.P1-3-tier-archi.id

  ingress {
    description     = "Allow traffic from Web tier ALB"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.webtier-alb-sg.id]
  }
  # For the ease of stress testing, we have allow ssh from anywhere. For security reasons, ssh should not be allowed or should restrict to specific IP address. 
  ingress {
    description = "ssh for stress test "
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }    

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Webtier-SG"
  }
}

# Create a webtier launch template
resource "aws_launch_template" "Webtier-launch-template" {
  name          = "Webtier-launch-template"
  description   = "Launch Template for Web Tier"
  image_id      = var.amis
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.webtier-sg.id]
  }
  
  key_name = aws_key_pair.P1_3tier_archi_keypair.key_name
  
  metadata_options {
    http_endpoint  = "enabled"
  }
  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Webtier template"
    }
  }
  user_data = filebase64("${path.module}/install_apache_web.sh")
}

# Create Webtier application load balancer
resource "aws_lb" "webtier-alb" {
  name               = "Webtier-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.webtier-alb-sg.id]
  subnets            = [for subnet in aws_subnet.public_webtier_subnet : subnet.id]
}

# Create Webtier application load balancer target group
resource "aws_lb_target_group" "webtier-alb-tg" {
  name     = "Webtier-ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.P1-3-tier-archi.id
}

# Create Webtier application load balancer listener
resource "aws_lb_listener" "webtier-alb" {
  load_balancer_arn = aws_lb.webtier-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webtier-alb-tg.arn
  }
}
# Create Webtier autoscaling group
resource "aws_autoscaling_group" "Webtier-ASG" {
  name                      = "Web-tier-ASG"
  max_size                  = 4
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = false
  target_group_arns         = [ aws_lb_target_group.webtier-alb-tg.arn ]  
  vpc_zone_identifier       = [for subnet in aws_subnet.public_webtier_subnet : subnet.id]
  launch_template {
    id      = aws_launch_template.Webtier-launch-template.id
    version = "$Latest"
  }
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "webtier-ASG"
    propagate_at_launch = true
  }

}

# Creating the AWS Cloudwatch Alarm that will scale up when CPU utilization increase.
resource "aws_autoscaling_policy" "webtier-autoscaling-policy-up" {
  name                   = "webtier-autoscaling-policy-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.Webtier-ASG.name
}

resource "aws_cloudwatch_metric_alarm" "webtier-cpu-alarm-up" {
  alarm_name          = "webtier-cpu-alarm-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "50"
  alarm_actions       = [
    aws_autoscaling_policy.webtier-autoscaling-policy-up.arn
    ]
  dimensions          = {
    AutoScalingGroupName = aws_autoscaling_group.Webtier-ASG.name
    }
}

# Creating the AWS Cloudwatch Alarm that will scale down when CPU utilization decrease.
resource "aws_autoscaling_policy" "webtier-autoscaling-policy-down" {
  name                   = "webtier-autoscaling-policy-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.Webtier-ASG.name
}

resource "aws_cloudwatch_metric_alarm" "webtier_cpu_alarm_down" {
  alarm_name          = "webtier_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "20"
  alarm_actions       = [
    aws_autoscaling_policy.webtier-autoscaling-policy-down.arn
    ]
  dimensions          = {
    AutoScalingGroupName = aws_autoscaling_group.Webtier-ASG.name
  }
}

