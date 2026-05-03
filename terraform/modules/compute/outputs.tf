output "instance_id" {
  description = "OCID da instância criada"
  value       = oci_core_instance.this.id
}

output "instance_name" {
  description = "Nome da instância"
  value       = oci_core_instance.this.display_name
}

output "private_ip" {
  description = "IP Privado da instância"
  value       = oci_core_instance.this.private_ip
}

output "boot_volume_id" {
  description = "OCID do volume de boot da instância"
  value       = oci_core_instance.this.boot_volume_id
}