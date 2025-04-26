# Create App Tier ALB Security Group
resource "aws_security_group" "apptier-alb-sg" {
  name        = "Apptier-ALB-SG"
  description = "Allow HTTP and HTTPS from webtier"
  vpc_id      = aws_vpc.P1-3-tier-archi.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.webtier-sg.id]
  }

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.webtier-sg.id]
  }    

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Apptier-ALB-SG"
  }
}

# Create App Tier Security Group
resource "aws_security_group" "apptier-sg" {
  name        = "Apptier-SG"
  description = "Allow inbound traffic from apptier ALB"
  vpc_id      = aws_vpc.P1-3-tier-archi.id

  ingress {
    description     = "Allow traffic from apptier alb"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.apptier-alb-sg.id]
  }

  # Allow ssh from bastion host. 
  ingress {
    description = "Allow ssh from bastion host"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion-host-sg.id]
  }    

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Apptier-SG"
  }
}

# Create apptier launch template
resource "aws_launch_template" "Apptier-launch-template" {
  name          = "Apptier-launch-template"
  description   = "Launch Template for App Tier"
  image_id      = var.amis
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.apptier-sg.id]
  key_name               = aws_key_pair.P1_3tier_archi_keypair.key_name
  
  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Apptier template"
    }
  }
  user_data = filebase64("${path.module}/install_db_app.sh")
}

# Create Apptier application load balancer
resource "aws_lb" "apptier-alb" {
  name               = "Apptier-LB"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.apptier-alb-sg.id]
  subnets            = [for subnet in aws_subnet.private_apptier_subnet : subnet.id] 
}

# Create Apptier application load balancer target group
resource "aws_lb_target_group" "apptier-alb-tg" {
  name     = "Apptier-ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.P1-3-tier-archi.id
}

# Create Apptier application load balancer listener
resource "aws_lb_listener" "apptier-alb" {
  load_balancer_arn = aws_lb.apptier-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.apptier-alb-tg.arn
  }
}
# Create Apptier autoscaling group
resource "aws_autoscaling_group" "Apptier-ASG" {
  name                      = "App-tier-ASG"
  max_size                  = 4
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = false
  target_group_arns = [ aws_lb_target_group.apptier-alb-tg.arn ]  
  vpc_zone_identifier       = [for subnet in aws_subnet.private_apptier_subnet : subnet.id]
  launch_template {
    id      = aws_launch_template.Apptier-launch-template.id
    version = "$Latest"
  }
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "Apptier-ASG"
    propagate_at_launch = true
  }

}

# Creating the AWS Cloudwatch Alarm that will scale up when CPU utilization increase.
resource "aws_autoscaling_policy" "apptier-autoscaling-policy-up" {
  name                   = "apptier-autoscaling-policy-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.Apptier-ASG.name
}

resource "aws_cloudwatch_metric_alarm" "apptier-cpu-alarm-up" {
  alarm_name          = "apptier-cpu-alarm-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "50"
  alarm_actions       = [
    aws_autoscaling_policy.apptier-autoscaling-policy-up.arn
    ]
  dimensions          = {
    AutoScalingGroupName = aws_autoscaling_group.Apptier-ASG.name
    }
}

# Creating the AWS Cloudwatch Alarm that will scale down when CPU utilization decrease.
resource "aws_autoscaling_policy" "apptier-autoscaling-policy-down" {
  name                   = "apptier-autoscaling-policy-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.Apptier-ASG.name
}

resource "aws_cloudwatch_metric_alarm" "apptier_cpu_alarm_down" {
  alarm_name          = "apptier_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "20"
  alarm_actions       = [
    aws_autoscaling_policy.apptier-autoscaling-policy-down.arn
    ]
  dimensions          = {
    AutoScalingGroupName = aws_autoscaling_group.Apptier-ASG.name
    }
}

