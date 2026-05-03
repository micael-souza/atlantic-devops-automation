# --- DATA SOURCES ---
# Busca a política de backup existente
data "oci_core_volume_backup_policies" "backup_policy" {
  compartment_id = var.compartment_id
  filter {
    name   = "display_name"
    values = ["life-cycle-backup"]
  }
}

# Gera a chave SSH
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Salva a chave localmente
resource "local_file" "private_key_pem" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/${var.instance_name}.pem"
  file_permission = "0600"
}

# ==========================================
# 1. CRIANDO O SERVIDOR (Chamando o Módulo)
# ==========================================
module "servidor" {
  source = "./modules/compute" # Aponta para a pasta do módulo

  compartment_id      = var.compartment_id
  availability_domain = local.ad
  subnet_id           = var.subnet_id
  image_id            = var.image_id
  instance_name       = var.instance_name
  shape               = local.instance_shape
  ocpus               = local.ocpus
  memory_in_gbs       = local.memory_in_gbs
  ssh_public_key      = tls_private_key.ssh_key.public_key_openssh
}

# Aplica política de backup no disco de boot usando o output do módulo
resource "oci_core_volume_backup_policy_assignment" "boot_backup" {
  asset_id  = module.servidor.boot_volume_id
  policy_id = data.oci_core_volume_backup_policies.backup_policy.volume_backup_policies[0].id
}

# ==========================================
# 2. CRIANDO OS DISCOS (Chamando o Módulo)
# ==========================================

# Disco 1: AdAlive-Apps
module "disco_adalive_apps" {
  source = "./modules/storage"

  availability_domain = local.ad
  compartment_id      = var.compartment_id
  display_name        = "tst-col-101-adalive-apps"
  size_in_gbs         = 100
  instance_id         = module.servidor.instance_id # Pega o ID gerado pelo módulo acima!
  backup_policy_id    = data.oci_core_volume_backup_policies.backup_policy.volume_backup_policies[0].id
}

# Disco 2: U01
module "disco_u01" {
  source = "./modules/storage"

  availability_domain = local.ad
  compartment_id      = var.compartment_id
  display_name        = "tst-col-101-u01"
  size_in_gbs         = 100
  instance_id         = module.servidor.instance_id
  backup_policy_id    = data.oci_core_volume_backup_policies.backup_policy.volume_backup_policies[0].id
}