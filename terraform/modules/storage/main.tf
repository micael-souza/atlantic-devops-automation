# 1. Criação do Disco Adicional (Block Volume)
resource "oci_core_volume" "this" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = var.display_name
  size_in_gbs         = var.size_in_gbs
}

# 2. Associa a Política de Backup ao Disco
resource "oci_core_volume_backup_policy_assignment" "this" {
  asset_id  = oci_core_volume.this.id
  policy_id = var.backup_policy_id
}

# 3. Faz a conexão (Attach) do Disco na Instância via iSCSI
resource "oci_core_volume_attachment" "this" {
  attachment_type = "iscsi"
  instance_id     = var.instance_id
  volume_id       = oci_core_volume.this.id
}