resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.app_sg_id]
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
dnf update -y
dnf install -y docker
systemctl enable docker
systemctl start docker
echo "healthy" > /var/www/html/healthz.html || true
EOF
  )
}

resource "aws_autoscaling_group" "this" {
  name                = "${var.name}-asg"
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size
  vpc_zone_identifier = var.app_subnet_ids
  target_group_arns   = [var.target_group_arn]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
}
