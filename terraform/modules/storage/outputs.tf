output "volume_id" {
  description = "OCID do volume criado"
  value       = oci_core_volume.this.id
}

output "iscsi_ipv4" {
  description = "IP do target iSCSI"
  value       = oci_core_volume_attachment.this.ipv4
}

output "iscsi_iqn" {
  description = "IQN do target iSCSI"
  value       = oci_core_volume_attachment.this.iqn
}

output "iscsi_port" {
  description = "Porta do target iSCSI"
  value       = oci_core_volume_attachment.this.port
}