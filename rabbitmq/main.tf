data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_region" "current" {
}

locals {
  cluster_name = "rabbitmq-${var.name}"
}

resource "random_string" "admin_password" {
  length  = 32
  special = false
}

resource "random_string" "rabbit_password" {
  length  = 32
  special = false
}

resource "random_string" "secret_cookie" {
  length  = 64
  special = false
}

data "aws_iam_policy_document" "policy_doc" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "template_file" "cloud-init" {
  template = file("${path.module}/cloud-init.yaml")

  vars = {
    sync_node_count        = 3
    asg_name              = local.cluster_name
    region                = data.aws_region.current.name
    admin_password        = random_string.admin_password.result
    rabbit_password       = random_string.rabbit_password.result
    secret_cookie         = random_string.secret_cookie.result
    message_timeout       = 3 * 24 * 60 * 60 * 1000 # 3 days
    rabbitmq_backup_bucket = var.rabbitmq_backup_bucket
  }
}

resource "aws_iam_role" "role" {
  name               = local.cluster_name
  assume_role_policy = data.aws_iam_policy_document.policy_doc.json
  description        = "IAM role for RabbitMQ cluster"
}

resource "aws_iam_role_policy" "policy" {
  name = local.cluster_name
  role = aws_iam_role.role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:Describe*",
          "ec2:Describe*"
        ],
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${var.rabbitmq_backup_bucket}/definitions/*"
      },
      {
        Action = [
          "s3:ListBucket"
        ],
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${var.rabbitmq_backup_bucket}"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "profile" {
  name_prefix = local.cluster_name
  role        = aws_iam_role.role.name
}

resource "aws_security_group" "rabbitmq_nodes" {
  name        = "${local.cluster_name}-nodes"
  vpc_id      = var.vpc_id
  description = "Security Group for the rabbitmq nodes"

  ingress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = var.cidr_blocks
  }

  ingress {
    protocol    = "tcp"
    from_port   = 5672
    to_port     = 5672
    cidr_blocks = var.cidr_blocks
  }

  ingress {
    protocol  = "tcp"
    from_port = 15672
    to_port   = 15672
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  ingress {
    description = "RabbitMQ node-to-node (EPMD)"
    from_port   = 4369
    to_port     = 4369
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks
  }

  ingress {
    description = "RabbitMQ node-to-node (cluster port)"
    from_port   = 25672
    to_port     = 25672
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks
  }

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = {
    Name = "rabbitmq ${var.name} nodes"
  }
}

resource "aws_launch_template" "rabbitmq" {
  name          = local.cluster_name
  image_id      = "ami-0731becbf832f281e" #AMI for Ubuntu 20.04 LTS in us-east-1
  instance_type = var.instance_type
  key_name      = var.ssh_key_name
  user_data     = base64encode(data.template_file.cloud-init.rendered)

  tags = {
    Environment = var.Environment
    Terraform   = "true"
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.profile.name
  }

  network_interfaces {
    associate_public_ip_address = var.is_public
    security_groups = [
      aws_security_group.rabbitmq_nodes.id
    ]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "rabbitmq" {
  name             = local.cluster_name
  min_size         = var.min_size
  desired_capacity = var.desired_size
  max_size         = var.max_size
  force_delete     = true
  launch_template {
    id      = aws_launch_template.rabbitmq.id
    version = "$Latest"
  }
  vpc_zone_identifier = var.subnet_ids

  tag {
    key                 = "Name"
    value               = local.cluster_name
    propagate_at_launch = true
  }
}

# S3 bucket for RabbitMQ definitions backup
resource "aws_s3_bucket" "rabbitmq_backup" {
  count  = var.create_backup_bucket ? 1 : 0
  bucket = var.rabbitmq_backup_bucket

  tags = {
    Name        = "RabbitMQ Definitions Backup"
    Environment = var.Environment
    Terraform   = "true"
  }
}

resource "aws_s3_bucket_versioning" "rabbitmq_backup_versioning" {
  count  = var.create_backup_bucket ? 1 : 0
  bucket = aws_s3_bucket.rabbitmq_backup[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "rabbitmq_backup_lifecycle" {
  count  = var.create_backup_bucket ? 1 : 0
  bucket = aws_s3_bucket.rabbitmq_backup[0].id

  rule {
    id     = "delete_old_definitions"
    status = "Enabled"

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}
