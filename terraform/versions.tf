# versions.tf

terraform {
  required_version = "~> 1.4"

  required_providers {
    google     = "~> 4.53"
    aws        = "~> 5.20"
    azurerm     = "~> 3.33"

    kubernetes = "~> 2.16"
    helm       = "~> 2.7"

    random     = "~> 3.1"
    external   = "~> 2.2"
    local      = "~> 2.2"
  }
}

