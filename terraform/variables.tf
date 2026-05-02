variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" { default = "sa-saopaulo-1" }

variable "compartment_id" {
  description = "ocid1.compartment.oc1..aaaaaaaavtrdfnushzhy66eyxmgoxjh2bosnybao7rdba24ddoag5yoe7n2a"
}

variable "subnet_id" {
  description = "ocid1.subnet.oc1.sa-saopaulo-1.aaaaaaaax4msykot2gdaspju25soiwjufnvhtoqr5nzt66vkusdhk4aquyca"
}

variable "image_id" {
  description = "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaacimohwuizo5fsdmp64ururv3glp2o2b6p5326kej55ju3jygotjq"
}

variable "instance_name" {
  default = "tst-col-101"
}