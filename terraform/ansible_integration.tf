resource "local_file" "ansible_vars" {
  content = templatefile("${path.module}/templates/ansible_vars.tpl", {
    # Variáveis do Disco 1 (Buscando do módulo)
    iscsi_ip   = module.disco_adalive_apps.iscsi_ipv4
    iscsi_port = module.disco_adalive_apps.iscsi_port
    iscsi_iqn  = module.disco_adalive_apps.iscsi_iqn

    # Variáveis do Disco 2 (Buscando do módulo)
    iscsi_ip_u01   = module.disco_u01.iscsi_ipv4
    iscsi_port_u01 = module.disco_u01.iscsi_port
    iscsi_iqn_u01  = module.disco_u01.iscsi_iqn
  })
  filename = "${path.module}/iscsi_vars.yml"
}