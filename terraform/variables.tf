variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" { default = "sa-saopaulo-1" }

variable "compartment_id" {
  description = "compartimento oci movix360"
}

variable "subnet_id" {
  description = "subnet privada movix360"
}

variable "image_id" {
  description = "imagem ubuntu 22.04 adalive v2"
}

variable "instance_name" {
  default = "prd-maestria-101"
}

variable "ssh_public_key" {
  description = "Chave SSH pública injetada pelo GitHub Actions"
  type        = string
}