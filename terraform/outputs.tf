output "secondary_instance_id" {
  value = aws_instance.secondary_instance.id
  description = "The ID of the secondary EC2 instance"
}

output "secondary_instance_public_ip" {
  value = aws_instance.secondary_instance.public_ip
  description = "The public IP address of the secondary EC2 instance"
}

output "secondary_security_group_id" {
  value = aws_security_group.secondary_sg.id
  description = "The ID of the secondary security group"
}

output "secondary_public_subnet_id" {
  value = aws_subnet.secondary_public_subnet.id
  description = "The ID of the secondary public subnet"
}

output "secondary_private_subnet_id" {
  value = aws_subnet.secondary_private_subnet.id
  description = "The ID of the secondary private subnet"
}

output "hosted_zone_id" {
  value = aws_route53_zone.MRD-route.zone_id
}