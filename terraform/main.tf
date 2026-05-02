# --- DATA SOURCES ---
# Coloque no topo ou logo antes de usar, para buscar a política pelo nome
data "oci_core_volume_backup_policies" "backup_policy" {

  compartment_id = var.compartment_id

  filter {
    name   = "display_name"
    values = ["life-cycle-backup"]
  }
}

# Geração da chave SSH privada
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Salva o arquivo .pem localmente
resource "local_file" "private_key_pem" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/${var.instance_name}.pem"
  file_permission = "0600"
}

resource "oci_core_instance" "this" {
  display_name        = var.instance_name
  compartment_id      = var.compartment_id
  availability_domain = local.ad
  fault_domain        = "FAULT-DOMAIN-1"
  shape               = local.instance_shape

  shape_config {
    ocpus         = local.ocpus
    memory_in_gbs = local.memory_in_gbs
  }

  source_details {
    source_type             = "image"
    source_id               = var.image_id
    boot_volume_size_in_gbs = 50
    boot_volume_vpus_per_gb = 10
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    display_name     = "primary-vnic"
    assign_public_ip = false
    hostname_label   = var.instance_name
  }

  metadata = {
    ssh_authorized_keys = tls_private_key.ssh_key.public_key_openssh
  }
}
# 1. Aplicar a política ao Volume de Boot da Instância
resource "oci_core_volume_backup_policy_assignment" "boot_volume_backup_policy_assignment" {
  asset_id  = oci_core_instance.this.boot_volume_id
  policy_id = data.oci_core_volume_backup_policies.backup_policy.volume_backup_policies[0].id
}

# Criação do Disco Adicional AdAlive-Apps
resource "oci_core_volume" "adalive_apps_disk" {
  availability_domain = local.ad
  compartment_id      = var.compartment_id
  display_name        = "tst-col-101-adalive-apps"
  size_in_gbs         = 50
}

# Associa a Política de Backup ao Disco adiconal AdAlive-Apps
resource "oci_core_volume_backup_policy_assignment" "policy_assignment" {
  asset_id  = oci_core_volume.adalive_apps_disk.id
  policy_id = data.oci_core_volume_backup_policies.backup_policy.volume_backup_policies[0].id
}

# Faz a conexão (Attach) do Disco AdAlive-Apps na Instância via iSCSI
resource "oci_core_volume_attachment" "adalive_apps_attachment" {
  attachment_type = "iscsi"
  instance_id     = oci_core_instance.this.id
  volume_id       = oci_core_volume.adalive_apps_disk.id
}

# Criação do Disco Adicional u01
resource "oci_core_volume" "u01_disk" {
  availability_domain = local.ad
  compartment_id      = var.compartment_id
  display_name        = "tst-col-101-u01"
  size_in_gbs         = 100
}

# Associa a Política de Backup ao Disco u01
resource "oci_core_volume_backup_policy_assignment" "u01_policy_assignment" {
  asset_id  = oci_core_volume.u01_disk.id
  policy_id = data.oci_core_volume_backup_policies.backup_policy.volume_backup_policies[0].id
}

# Faz a conexão (Attach) do Disco u01 na Instância via iSCSI
resource "oci_core_volume_attachment" "u01_attachment" {
  attachment_type = "iscsi"
  instance_id     = oci_core_instance.this.id
  volume_id       = oci_core_volume.u01_disk.id
}