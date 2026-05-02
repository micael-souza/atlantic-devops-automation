# --- INTEGRAÇÃO TERRAFORM -> ANSIBLE ---
resource "local_file" "ansible_vars" {
  content = templatefile("${path.module}/templates/ansible_vars.tpl", {
    # Variáveis do Disco 1 (AdAlive-Apps)
    iscsi_ip   = oci_core_volume_attachment.adalive_apps_attachment.ipv4
    iscsi_port = oci_core_volume_attachment.adalive_apps_attachment.port
    iscsi_iqn  = oci_core_volume_attachment.adalive_apps_attachment.iqn

    # Variáveis do Disco 2 (u01)
    iscsi_ip_u01   = oci_core_volume_attachment.u01_attachment.ipv4
    iscsi_port_u01 = oci_core_volume_attachment.u01_attachment.port
    iscsi_iqn_u01  = oci_core_volume_attachment.u01_attachment.iqn
  })
  filename = "${path.module}/iscsi_vars.yml"
}