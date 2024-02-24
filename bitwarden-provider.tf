variable "bitwarden_master_password" {
  type      = string
  sensitive = true
}

variable "bitwarden_client_id" {
  type      = string
  sensitive = true
}

variable "bitwarden_client_secret" {
  type      = string
  sensitive = true
}

variable "bitwarden_email" {
  type      = string
  sensitive = true
}

provider "bitwarden" {
  master_password = var.bitwarden_master_password
  client_id       = var.bitwarden_client_id
  client_secret   = var.bitwarden_client_secret
  email           = var.bitwarden_email
}
