terraform {
  required_providers {
    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.10"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.2"
    }
  }
}

provider "b2" {}

provider "random" {}

provider "vault" {}
