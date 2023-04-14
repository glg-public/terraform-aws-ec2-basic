output "public_ip" {
  description = "Public IP of instance (or EIP)"
  value       = concat(aws_eip.default.*.public_ip, aws_instance.default.*.public_ip, [""])[0]
}

output "private_ip" {
  description = "Private IP of instance"
  value       = join("", aws_instance.default.*.private_ip)
}

output "private_dns" {
  description = "Private DNS of instance"
  value       = join("", aws_instance.default.*.private_dns)
}

output "public_dns" {
  description = "Public DNS of instance (or DNS of EIP)"
  value       = local.public_dns
}

output "id" {
  description = "Disambiguated ID of the instance"
  value       = join("", aws_instance.default.*.id)
}

output "name" {
  description = "Instance name"
  value       = local.instance_name
}

output "ssh_key_pair" {
  description = "Name of the SSH key pair provisioned on the instance"
  value       = var.ssh_key_pair
}

output "security_group_ids" {
  description = "IDs on the AWS Security Groups associated with the instance"
  value = compact(
    concat(
      [var.create_default_security_group == true ? join("", aws_security_group.default.*.id) : ""],
      var.security_groups
    )
  )
}

output "role" {
  description = "Name of AWS IAM Role associated with the instance"
  value       = var.iam_profile_name
}

output "additional_eni_ids" {
  description = "Map of ENI to EIP"
  value = zipmap(
    aws_network_interface.additional.*.id,
    aws_eip.additional.*.public_ip
  )
}

output "primary_network_interface_id" {
  description = "ID of the instance's primary network interface"
  value       = join("", aws_instance.default.*.primary_network_interface_id)
}
