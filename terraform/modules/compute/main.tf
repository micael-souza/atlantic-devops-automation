resource "oci_core_instance" "this" {
  display_name        = var.instance_name
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  fault_domain        = "FAULT-DOMAIN-1"
  shape               = var.shape

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
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
    ssh_authorized_keys = var.ssh_public_key
  }
}