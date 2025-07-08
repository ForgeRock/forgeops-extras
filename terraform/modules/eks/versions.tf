# versions.tf

terraform {
  required_providers {
    aws        = "~> 5.100"

    kubernetes = "~> 2.37"
    helm       = "~> 3.0"

    random     = "~> 3.7"
    external   = "~> 2.3"
    local      = "~> 2.5"
  }
}

