# versions.tf

terraform {
  required_version = "~> 1.4"

  required_providers {
    google     = "~> 5.31"
    aws        = "~> 5.100"
    azurerm     = "~> 3.105"

    kubernetes = "~> 2.37"
    helm       = "~> 3.0"

    random     = "~> 3.7"
    external   = "~> 2.3"
    local      = "~> 2.5"
  }
}

