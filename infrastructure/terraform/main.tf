# AI Website Builder - AWS Lightsail Infrastructure
# Provisions a Lightsail instance with 1 CPU and 1GB RAM running Ubuntu LTS

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Lightsail instance with 1 CPU and 1GB RAM
resource "aws_lightsail_instance" "website_builder" {
  name              = var.instance_name
  availability_zone = "${var.aws_region}a"
  blueprint_id      = "ubuntu_22_04"  # Ubuntu 22.04 LTS
  bundle_id         = "nano_2_0"      # 1 CPU, 1GB RAM ($7/month)
  
  user_data = file("${path.module}/user-data.sh")
  
  tags = {
    Name        = var.instance_name
    Environment = var.environment
    Project     = "ai-website-builder"
    ManagedBy   = "terraform"
  }
}

# Static IP for the instance
resource "aws_lightsail_static_ip" "website_builder" {
  name = "${var.instance_name}-static-ip"
}

resource "aws_lightsail_static_ip_attachment" "website_builder" {
  static_ip_name = aws_lightsail_static_ip.website_builder.name
  instance_name  = aws_lightsail_instance.website_builder.name
}

# Open ports 80, 443, and Tailscale port (41641 UDP)
resource "aws_lightsail_instance_public_ports" "website_builder" {
  instance_name = aws_lightsail_instance.website_builder.name

  port_info {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
    cidrs     = ["0.0.0.0/0"]
  }

  port_info {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
    cidrs     = ["0.0.0.0/0"]
  }

  port_info {
    protocol  = "udp"
    from_port = 41641
    to_port   = 41641
    cidrs     = ["0.0.0.0/0"]
  }
}
