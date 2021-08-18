provider "aws" {
  version = "3.45.0"
  region  = "us-east-1"
}

terraform {
  required_version = "0.13.7"
}

locals {
  name_prefix = "serviceX-"
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

// Role to assume the ec2 service - required for ec2 instances and IAM
resource "aws_iam_role" "default" {
  name_prefix        = local.name_prefix
  assume_role_policy = file("${path.module}/policies/assume-role.json")
  tags               = local.default_tags
}

// Inline policy that allows instance to perform tasks we define
resource "aws_iam_role_policy" "default" {
  name_prefix = local.name_prefix
  policy      = file("${path.module}/policies/serviceX-role.json")
  role        = aws_iam_role.default.id
}

// Attaching an AWS managed policy
resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

// A profile is a role container
resource "aws_iam_instance_profile" "default" {
  name_prefix = local.name_prefix
  role        = aws_iam_role.default.name
  tags        = local.default_tags
}

module "some_amazon_linux_server" {
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

  source                      = "../../"
  instance_type               = "t3.micro"
  ami                         = "ami-0aeeebd8d2ab47354" // Amazon Linux 2
  security_groups             = [aws_security_group.servers.id]
  delete_on_termination       = true
  associate_public_ip_address = true # needed for SSM!
  namespace                   = "glg"
  stage                       = "test"
  root_volume_size            = 100
  root_volume_type            = "gp3"
  user_data                   = data.template_file.user_data.rendered
  iam_profile_name            = aws_iam_instance_profile.default.name
  monitoring                  = false
  vpc_id                      = data.aws_vpc.primary.id
  assign_eip_address          = false
  disable_api_termination     = false # Disables "Termination Protection" in the GUI
  ebs_volume_count            = 2     # creates two additional EBS volumes
  ebs_volume_size             = 10
  ebs_device_name             = ["/dev/xvdb", "/dev/xvdc"] # map first two drives on Linux machine
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
