# versions.tf

terraform {
  required_providers {
    aws        = "~> 5.51"

    kubernetes = "~> 2.30"
    helm       = "~> 2.13"

    random     = "~> 3.6"
    external   = "~> 2.3"
    local      = "~> 2.5"
  }
}

