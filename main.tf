locals {
  instance_count       = var.instance_enabled ? 1 : 0
  security_group_count = var.create_default_security_group ? 1 : 0
  region               = var.region != "" ? var.region : data.aws_region.default.name
  ebs_iops             = var.ebs_volume_type == "io1" ? var.ebs_iops : "0"
  availability_zone    = var.availability_zone != "" ? var.availability_zone : data.aws_subnet.default.availability_zone
  public_dns           = var.associate_public_ip_address && var.assign_eip_address && var.instance_enabled ? data.null_data_source.eip.outputs["public_dns"] : join("", aws_instance.default.*.public_dns)
}

module "label" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  namespace   = var.namespace        # ""
  stage       = var.stage            # DEV-SQL
  environment = var.environment      # ""
  name        = var.name             # GP-TEST 
  attributes  = var.attributes       # []
  delimiter   = var.delimiter        # ": "
  enabled     = var.instance_enabled # true 
  tags        = var.tags             # local.default_tags
}

locals {
  instance_tags = {
    Name            = "${var.stage}${var.delimiter} ${var.name}"
    AlertLogic      = "Install"
    Rapid7          = "Install"
    SpendAllocation = "Database Disk"
  }
}

#default_tags = {
#  "BusinessUnit"    = "Core Engineering"
#  "Environment"     = "Development"
#  "ManagedBy"       = "Terraform"
#  "Owner"           = "DRE"
#  "App"             = "Great Plains"
#  "GitHub"          = "https://github.com/glg/metadevops-issues/issues/622"
#  "Terraform"       = "https://github.com/glg/aws-infrastructure/tree/master/glgapp/dre/great-plains-sql-servers"
#  "hostname"        = "IP-AC1B0594"
#}

data "aws_caller_identity" "default" {
}

data "aws_region" "default" {
}

data "aws_partition" "default" {
}

data "aws_subnet" "default" {
  id = var.subnet
}

data "aws_iam_policy_document" "default" {
  statement {
    sid = ""

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    effect = "Allow"
  }
}

resource "aws_instance" "default" {
  count                       = local.instance_count
  ami                         = var.ami
  availability_zone           = local.availability_zone
  instance_type               = var.instance_type
  ebs_optimized               = var.ebs_optimized
  disable_api_termination     = var.disable_api_termination
  user_data                   = var.user_data
  iam_instance_profile        = var.iam_profile_name
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = var.ssh_key_pair
  subnet_id                   = var.subnet
  monitoring                  = var.monitoring
  private_ip                  = var.private_ip
  source_dest_check           = var.source_dest_check
  ipv6_address_count          = var.ipv6_address_count < 0 ? null : var.ipv6_address_count
  ipv6_addresses              = length(var.ipv6_addresses) == 0 ? null : var.ipv6_addresses

  vpc_security_group_ids = compact(
    concat(
      [
        var.create_default_security_group ? join("", aws_security_group.default.*.id) : "",
      ],
      var.security_groups
    )
  )

  root_block_device {
    encrypted             = var.root_block_device_encryption
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    iops                  = var.root_iops
    delete_on_termination = var.delete_on_termination
  }

  tags = merge(local.instance_tags, var.tags)
}

resource "aws_eip" "default" {
  count             = var.associate_public_ip_address && var.assign_eip_address && var.instance_enabled ? 1 : 0
  network_interface = join("", aws_instance.default.*.primary_network_interface_id)
  vpc               = true
  tags              = module.label.tags
}

data "null_data_source" "eip" {
  inputs = {
    public_dns = "ec2-${replace(join("", aws_eip.default.*.public_ip), ".", "-")}.${local.region == "us-east-1" ? "compute-1" : "${local.region}.compute"}.amazonaws.com"
  }
}

resource "aws_ebs_volume" "default" {
  count             = var.ebs_volume_count
  availability_zone = local.availability_zone
  size              = var.ebs_volume_size
  iops              = local.ebs_iops
  type              = var.ebs_volume_type
  tags              = module.label.tags
  encrypted         = var.ebs_volume_encrypted
  kms_key_id        = var.kms_key_id
}

resource "aws_volume_attachment" "default" {
  count       = var.ebs_volume_count
  device_name = var.ebs_device_name[count.index]
  volume_id   = aws_ebs_volume.default.*.id[count.index]
  instance_id = join("", aws_instance.default.*.id)
}
