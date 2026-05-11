terraform {
  backend "s3" {
    bucket = "ob-tf-state-terraform"
    key    = "prd-maestria-101/terraform.tfstate"
    region = "sa-saopaulo-1" # Ajuste se sua região for diferente

    # Endpoint da OCI (Substitua <NAMESPACE> pelo Namespace da sua Tenancy)
    endpoints = {
      s3 = "https://grqmasfgwzsp.compat.objectstorage.sa-saopaulo-1.oraclecloud.com"
    }

    use_path_style              = true
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

# --- DATA SOURCES ---
# Busca a política de backup existente
data "oci_core_volume_backup_policies" "backup_policy" {
  compartment_id = var.compartment_id
  filter {
    name   = "display_name"
    values = ["life-cycle-backup"]
  }
}
# ==========================================
# 0. GERAÇÃO DE CHAVE SSH PARA O TIME DE INFRA
# ==========================================
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Salva a chave privada localmente (no runner do GitHub)
resource "local_file" "private_key_pem" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/${var.instance_name}-time-infra.pem"
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

  # Injeta a sua chave (var.ssh_public_key) E a nova chave do time (tls_private_key...)
  ssh_public_key = "${var.ssh_public_key}\n${tls_private_key.ssh_key.public_key_openssh}"
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
  # Deixando o nome dinâmico baseado no nome do servidor!
  display_name     = "${var.instance_name}-adalive-apps"
  size_in_gbs      = 100
  instance_id      = module.servidor.instance_id # Pega o ID gerado pelo módulo acima!
  backup_policy_id = data.oci_core_volume_backup_policies.backup_policy.volume_backup_policies[0].id
}

# Disco 2: U01
module "disco_u01" {
  source = "./modules/storage"

  availability_domain = local.ad
  compartment_id      = var.compartment_id
  display_name        = "${var.instance_name}-u01"
  size_in_gbs         = 100
  instance_id         = module.servidor.instance_id
  backup_policy_id    = data.oci_core_volume_backup_policies.backup_policy.volume_backup_policies[0].id
}