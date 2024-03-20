# versions.tf

terraform {
  required_providers {
    google     = "~> 5.21"

    kubernetes = "~> 2.24"
    helm       = "~> 2.12"

    random     = "~> 3.6"
    external   = "~> 2.3"
    local      = "~> 2.4"
  }
}

