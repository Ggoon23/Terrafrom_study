output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.ec2_instance.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.ec2_instance.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.ec2_instance.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.ec2_instance.public_dns
}

output "elastic_ip" {
  description = "Elastic IP address"
  value       = aws_eip.ec2_eip.public_ip
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.ec2_sg.id
}

output "key_pair_name" {
  description = "Key Pair name"
  value       = aws_key_pair.ec2_key.key_name
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_eip.ec2_eip.public_ip}"
}