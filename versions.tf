terraform {
  required_version = "~> 1.2"

  required_providers {
    aws = {
      version = "~> 4.0"
    }
    null = {
      version = ">= 2.0"
    }
  }
}
