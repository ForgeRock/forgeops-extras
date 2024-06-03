# versions.tf

terraform {
  required_version = "~> 1.4"

  required_providers {
    google     = "~> 5.31"
    aws        = "~> 5.51"
    azurerm     = "~> 3.105"

    kubernetes = "~> 2.30"
    helm       = "~> 2.13"

    random     = "~> 3.6"
    external   = "~> 2.3"
    local      = "~> 2.5"
  }
}

