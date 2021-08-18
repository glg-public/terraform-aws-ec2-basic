provider "aws" {
  version = "3.31.0"
  region  = "us-east-1"
}

terraform {
  required_version = "0.13.7"
}

locals {
  default_tags = {
    "BusinessUnit" = "Engineering"
    "Environment"  = "Production"
    "ManagedBy"    = "Terraform"
    "Owner"        = "Sandy Hair"
    "App"          = "Great Pains"
    "GitHub"       = "https://github.com/oooo/622"
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data")
}

// clever tag to set on your non-default VPC
data "aws_vpc" "primary" {
  tags = {
    is_glg_default = "true"
  }
}

module "some_windows_server" {
  # unique per server:
  region            = "us-east-1"
  availability_zone = "us-east-1c"
  subnet            = "subnet-0e0e0e0"
  name              = "something-descriptive"
  tags = merge(
    local.default_tags,
    {
      "More"     = "Tags"
      "EvenMore" = "Tags"
    },
  )

  # no need to change these:
  source                        = "../../"
  instance_type                 = "t3.2xlarge"
  ami                           = "ami-07dcc3822b6f2bdbe" #Windows 2016 Base
  security_groups               = [aws_security_group.servers.id]
  delete_on_termination         = true
  ssh_key_pair                  = "prototype"
  associate_public_ip_address   = false
  namespace                     = "glg"
  stage                         = "test"
  root_volume_size              = 100
  root_volume_type              = "gp3"
  user_data                     = data.template_file.user_data.rendered
  iam_profile_name              = aws_iam_instance_profile.test_profile.name
  monitoring                    = false
  vpc_id                        = data.aws_vpc.primary.id
  create_default_security_group = false
  assign_eip_address            = false
  disable_api_termination       = true # Enables "Termination Protection" in the GUI
  ebs_volume_count              = 2    # creates two additional EBS volumes
  ebs_volume_size               = 10
  ebs_device_name               = ["xvdf", "xvdg"] # since this is a windows device, lose the /dev/ AND start with f (according to docs https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/device_naming.html#available-ec2-device-names)
}

resource "aws_security_group" "servers" {
  name        = "Servers"
  description = "Servers Security Group"
  vpc_id      = data.aws_vpc.primary.id

  ingress {
    description = "Cloud traffic from AWS CIDR ranges"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["172.16.0.0/12"]
  }

  ingress {
    description = "All access from office VLANs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    description = "Allow servers to reach OUT to internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.default_tags
}

resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "role" {
  name = "test_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}