variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "resource_group_name" {
  type    = string
  default = "rg-mythesis-streamflix-20260617"
}

variable "vm_name" {
  type    = string
  default = "vm-mythesis-streamflix-20260617"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "vm_size" {
  type    = string
  default = "Standard_E2s_v7"
}

variable "vm_zone" {
  type    = number
  default = 1
}

variable "ssh_public_key" {
  type = string
}

variable "ssh_source_cidr" {
  type    = string
  default = "84.226.95.4/32"
}

variable "app_repo" {
  type    = string
  default = "https://github.com/devopsinsiders/StreamFlix.git"
}

variable "app_branch" {
  type    = string
  default = "build"
}

variable "image_version" {
  type    = string
  default = "22.04.202606110"
}
