# terraform-aws-ec2-basic

## Overview

### Origin

This module is a hard-fork of version 0.17.0 of the Cloudposse `terterraform-aws-ec2-instance` module.
The documentation for the original parts of this module can be found
[here](https://github.com/cloudposse/terraform-aws-ec2-instance/tree/0.17.0)

### Goals

Easy EC2 module that is non-destructive by default. The idea is, that instance destruction
should be intentional, and not an effect of modifications to some parts of the IaC.  As such,
following changes will be ignored:

- `aws_instance`
  - `ami`
  - `user_data`
  - `ebs_optimized`
  - `instance_type`

If you really want an instance destroyed as part of an apply, use `terraform taint` to taint
the desired `aws_instance` resource.
