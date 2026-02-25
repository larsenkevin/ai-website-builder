# Variables for AWS Lightsail deployment

variable "aws_region" {
  description = "AWS region for Lightsail instance"
  type        = string
  default     = "us-east-1"
}

variable "instance_name" {
  description = "Name for the Lightsail instance"
  type        = string
  default     = "ai-website-builder"
}

variable "environment" {
  description = "Environment name (production, staging, etc.)"
  type        = string
  default     = "production"
}

variable "domain" {
  description = "Domain name for the website"
  type        = string
}

variable "ssl_email" {
  description = "Email address for Let's Encrypt SSL certificates"
  type        = string
}

variable "anthropic_api_key" {
  description = "Anthropic API key for Claude integration"
  type        = string
  sensitive   = true
}

variable "tailscale_auth_key" {
  description = "Tailscale authentication key for VPN setup"
  type        = string
  sensitive   = true
}
