# Outputs for AWS Lightsail deployment

output "instance_id" {
  description = "ID of the Lightsail instance"
  value       = aws_lightsail_instance.website_builder.id
}

output "instance_name" {
  description = "Name of the Lightsail instance"
  value       = aws_lightsail_instance.website_builder.name
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = aws_lightsail_static_ip.website_builder.ip_address
}

output "static_ip_name" {
  description = "Name of the static IP"
  value       = aws_lightsail_static_ip.website_builder.name
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh ubuntu@${aws_lightsail_static_ip.website_builder.ip_address}"
}

output "next_steps" {
  description = "Next steps after deployment"
  value       = <<-EOT
    Deployment complete! Next steps:
    
    1. Point your domain DNS to: ${aws_lightsail_static_ip.website_builder.ip_address}
    2. SSH into the instance: ssh ubuntu@${aws_lightsail_static_ip.website_builder.ip_address}
    3. Check deployment logs: sudo journalctl -u website-builder
    4. Access builder interface via Tailscale VPN on port 3000
    5. Public website will be available at: https://${var.domain}
  EOT
}
