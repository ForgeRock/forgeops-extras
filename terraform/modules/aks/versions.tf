# versions.tf

terraform {
  required_providers {
    azurerm = "~> 3.105"

    kubernetes = "~> 2.30"
    helm       = "~> 2.13"

    random     = "~> 3.6"
    external   = "~> 2.3"
    local      = "~> 2.5"
  }
}

