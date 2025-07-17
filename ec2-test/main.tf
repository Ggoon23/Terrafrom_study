# Data source to get default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source to get default subnet
data "aws_subnet" "default" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "${var.aws_region}a"
  default_for_az    = true
}

# Security Group
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "Security group for EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-sg"
  }
}

# Key Pair
resource "aws_key_pair" "ec2_key" {
  key_name   = var.key_name
  public_key = file("~/.ssh/id_rsa.pub") # 로컬 SSH 공개키 경로

  tags = {
    Name = "${var.project_name}-${var.environment}-key"
  }
}

# EC2 Instance
resource "aws_instance" "ec2_instance" {
  ami                     = var.ami_id
  instance_type           = var.instance_type
  key_name                = aws_key_pair.ec2_key.key_name
  subnet_id               = data.aws_subnet.default.id
  vpc_security_group_ids  = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  # User data script
  user_data = file("user_data.sh")

  # Root volume configuration
  root_block_device {
    volume_size           = var.volume_size
    volume_type           = var.volume_type
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.project_name}-${var.environment}-root-volume"
    }
  }

  # Instance metadata service configuration
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = var.instance_name
  }
}

# Elastic IP (선택사항)
resource "aws_eip" "ec2_eip" {
  instance = aws_instance.ec2_instance.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-eip"
  }

  depends_on = [aws_instance.ec2_instance]
}