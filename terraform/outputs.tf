output "instance_name" {
  value = oci_core_instance.this.display_name
}

output "private_ip" {
  value = oci_core_instance.this.private_ip
}

output "ssh_key_path" {
  value       = local_file.private_key_pem.filename
  description = "Caminho da chave gerada para acessar a instância"
}

output "iscsi_ipv4" {
  value       = oci_core_volume_attachment.adalive_apps_attachment.ipv4
  description = "IP do target iSCSI para o Ansible"
}

output "iscsi_iqn" {
  value       = oci_core_volume_attachment.adalive_apps_attachment.iqn
  description = "IQN do target iSCSI para o Ansible"
}

output "iscsi_port" {
  value       = oci_core_volume_attachment.adalive_apps_attachment.port
  description = "Porta de conexão iSCSI"
}