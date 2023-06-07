provider "vsphere" {
  user                 = "administrator@${var.sso_domain_name}"
  password             = var.sso_password
  vsphere_server       = var.network_system_name
  allow_unverified_ssl = true

  alias = "nested"
}


provider "vsphere" {
  user                 = "root"
  password = var.esxi_root_password
  vsphere_server       = var.esxi_ip_address
  allow_unverified_ssl = true
  alias = "esxi"
}

data "vsphere_host_thumbprint" "thumbprint" {
  provider = vsphere.esxi
  address  = var.esxi_ip_address
  insecure = true
}


resource "vsphere_datacenter" "nested_datacenter" {
  provider = vsphere.nested
  name     = "SDDC-Datacenter"

}

resource "vsphere_compute_cluster" "nested_cluster" {
  provider             = vsphere.nested
  name                 = "Cluster-1"
  datacenter_id        = vsphere_datacenter.nested_datacenter.moid
  drs_enabled          = true
  drs_automation_level = "fullyAutomated"
}

resource "vsphere_host" "h1" {
  provider   = vsphere.nested
  hostname   = var.esxi_ip_address
  username   = "root"
  password   = var.esxi_root_password
  cluster    = vsphere_compute_cluster.nested_cluster.id
  thumbprint = data.vsphere_host_thumbprint.thumbprint.id
}


resource "vsphere_distributed_virtual_switch" "dvs" {
  provider      = vsphere.nested
  name          = "DSwitch0"
  datacenter_id = vsphere_datacenter.nested_datacenter.moid

  uplinks        = ["uplink1"]
  active_uplinks = ["uplink1"]

  host {
    host_system_id = vsphere_host.h1.id
    devices        = ["vmnic1"]
  }
}
resource "vsphere_distributed_port_group" "pg" {
  name                            = "dev-segment"
  distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.dvs.id
}

