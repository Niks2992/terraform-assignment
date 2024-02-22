resource "aws_launch_configuration" "webserver" {
  name                        = var.launch_configuration_name
  image_id                    = var.image_id
  instance_type               = var.instance_type
  security_groups             = [var.security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data = <<-EOF
                #!/bin/bash
                sudo yum install -y httpd
                sudo yum install -y ansible
                sudo systemctl start httpd
                sudo systemctl enable httpd
                sudo ansible-pull -U https://github.com/Niks2992/terraform-assignment/blob/main/playbook.yaml             
                sudo systemctl restart httpd
                EOF

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    encrypted   = true
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/xvdf"
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name                      = var.autoscaling_group_name
  launch_configuration      = aws_launch_configuration.webserver.name
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.subnet_ids
  # vpc_zone_identifier       = [aws_subnet.first_public_subnet.id, aws_subnet.second_public_subnet.id]
  health_check_type         = "ELB"
  health_check_grace_period = 300
    tag {
    key                 = "Name"
    value               = var.autoscaling_group_name
    propagate_at_launch = true
  }
}

resource "aws_cloudwatch_metric_alarm" "cwalarm" {
  alarm_name          = var.alarm_name
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_description = "This metric monitors the CPU utilization of the Auto Scaling group."
  alarm_actions     = [var.notification_arn]
}

