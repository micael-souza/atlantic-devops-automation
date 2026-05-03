variable "compartment_id" {
  description = "OCID do compartimento onde a instância será criada"
  type        = string
}

variable "availability_domain" {
  description = "Availability Domain da OCI"
  type        = string
}

variable "subnet_id" {
  description = "OCID da subnet onde a instância será conectada"
  type        = string
}

variable "image_id" {
  description = "OCID da imagem (S.O.) da instância"
  type        = string
}

variable "instance_name" {
  description = "Nome de exibição da instância"
  type        = string
}

variable "shape" {
  description = "Shape da instância (ex: VM.Standard.E4.Flex)"
  type        = string
}

variable "ocpus" {
  description = "Quantidade de OCPUs"
  type        = number
}

variable "memory_in_gbs" {
  description = "Quantidade de Memória em GBs"
  type        = number
}

variable "ssh_public_key" {
  description = "Chave SSH pública autorizada para acesso"
  type        = string
}