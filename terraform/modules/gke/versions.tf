# versions.tf

terraform {
  required_providers {
    google     = "~> 5.31"

    kubernetes = "~> 2.30"
    helm       = "~> 2.13"

    random     = "~> 3.6"
    external   = "~> 2.3"
    local      = "~> 2.5"
  }
}

