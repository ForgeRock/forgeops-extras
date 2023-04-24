# versions.tf

terraform {
  required_providers {
    aws        = "~> 4.61"

    kubernetes = "~> 2.16"
    helm       = "~> 2.7"

    random     = "~> 3.1"
    external   = "~> 2.2"
    local      = "~> 2.2"
  }
}

