provider "vsphere" {
  user                 = var.vsphere_username
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_url
  allow_unverified_ssl = false
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

provider "vsphere" {
  user                 = "administrator@vsphere.local"
  password             = var.vcsa_password
  vsphere_server       = "${var.vcsa_hostname}.${var.base_domain}"
  allow_unverified_ssl = true

  alias = "nested"
}


module "vcsa" {
  source                = "../../modules/vcenter"
  vc_hostname           = var.vsphere_url
  vc_username           = var.vsphere_username
  vc_password           = var.vsphere_password
  vc_deployment_network = var.vsphere_network
  vc_target             = var.vsphere_cluster
  vc_datastore          = var.vsphere_datastore
  vc_datacenter         = var.vsphere_datacenter
  appliance_name        = var.vcsa_hostname
  network_ip            = var.vcsa_ip_address
  network_prefix        = var.vcsa_network_prefix
  network_gateway       = var.vcsa_network_gateway
  network_system_name   = aws_route53_record.a_record.fqdn
  os_password           = var.vcsa_password
  sso_password          = var.vcsa_password

esxi_root_password = var.esxi_root_password

  providers = {
    vsphere = vsphere.nested
  }
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

output "esxi_ip_address" {
  value = module.esxi.ip_address
}
