variable "availability_domain" {
  description = "Availability Domain onde o disco será criado"
  type        = string
}

variable "compartment_id" {
  description = "OCID do compartimento"
  type        = string
}

variable "display_name" {
  description = "Nome do disco"
  type        = string
}

variable "size_in_gbs" {
  description = "Tamanho do disco em GB"
  type        = number
}

variable "instance_id" {
  description = "OCID da instância onde o disco será atachado"
  type        = string
}

variable "backup_policy_id" {
  description = "OCID da política de backup que será aplicada ao disco"
  type        = string
}