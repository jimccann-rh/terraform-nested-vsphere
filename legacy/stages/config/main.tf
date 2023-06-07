provider "vsphere" {
  user                 = var.vsphere_username
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_url
  allow_unverified_ssl = false
}
data "vsphere_datacenter" "datacenter" {
  name = var.vsphere_datacenter
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.esxi_template_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}


data "vsphere_virtual_machine" "esxi" {
  name          = "esxi"
  datacenter_id = data.vsphere_datacenter.datacenter.id

}

data "aws_route53_zone" "base" {
  name = var.base_domain
}

resource "aws_route53_record" "a_record" {
  type    = "A"
  ttl     = "60"
  zone_id = data.aws_route53_zone.base.zone_id
  name    = var.vcsa_hostname
  records = [var.vcsa_ip_address]
}



provider "vsphere" {
  user                 = "administrator@vsphere.local"
  password             = var.vcsa_password
  vsphere_server       = "${var.vcsa_hostname}.${var.base_domain}"
  allow_unverified_ssl = true

  alias = "nested"
}

module "esxi" {
  source = "../../modules/esxi"

  resource_pool = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore     = data.vsphere_datastore.datastore.id
  network       = data.vsphere_network.network.id
  datacenter    = data.vsphere_datacenter.datacenter.id
  template      = data.vsphere_virtual_machine.template.id
  guest_id      = data.vsphere_virtual_machine.template.guest_id

}


module "vcsa_config" {
  source = "../../modules/config"

  network_system_name = aws_route53_record.a_record.fqdn
  sso_password        = var.vcsa_password
  //esxi_ip_address     = data.vsphere_virtual_machine.esxi.guest_ip_addresses[0]
  esxi_ip_address     = module.esxi.ip_address
esxi_root_password = var.esxi_root_password

  providers = {
    vsphere = vsphere.nested
  }
}

