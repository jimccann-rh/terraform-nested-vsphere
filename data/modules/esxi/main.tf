variable "vsphere_user" {
  type    = string
  default = "Administrator@devqe.ibmc.devcluster.openshift.com"
}
variable "vsphere_password" {
  type    = string
  default = ""
}
variable "vsphere_server" {
  type    = string
  default = "vcenter.devqe.ibmc.devcluster.openshift.com"
}
variable "content_library_name" {
  type    = string
  default = "nested"
}
variable "content_library_item_name" {
  type    = string
  default = "Nested_ESXi7.0u2a_Appliance_Template_v2.0"
}
variable "vsphere_datacenter" {
  type    = string
  default = "DEVQEdatacenter"
}
variable "vsphere_cluster" {
  type    = string
  default = "DEVQEcluster"
}
variable "vsphere_resource_pool" {
  type    = string
  default = ""
}
variable "vsphere_datastore" {
  type    = string
  default = "vsanDatastore"
}
variable "vsphere_network" {
  type    = string
  default = "devqe-segment-221"
}
variable "vsphere_esxi_host" {
  type = string
  default = "devqe-vmware-host-0.devqe.ibmc.devcluster.openshift.com"
}


variable "esxi_ova_url" {
  type    = string
  default = "https://download3.vmware.com/software/vmw-tools/nested-esxi/Nested_ESXi7.0u3_Appliance_Template_v1.ova"
}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

/* current does not work
data "vsphere_content_library" "nested" {
  name = var.content_library_name
}

data "vsphere_content_library_item" "esxi" {
  library_id = data.vsphere_content_library.nested.id
  type       = "ovf"
  name       = var.content_library_item_name
}
*/

data "vsphere_datacenter" "datacenter" {
  name = var.vsphere_datacenter
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

/*
data "vsphere_resource_pool" "resource_pool" {
  name  = var.vsphere_resource_pool
}
*/

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_host" "host" {
  name          = var.vsphere_esxi_host
  datacenter_id = data.vsphere_datacenter.datacenter.id
}


data "vsphere_ovf_vm_template" "esxi" {
  name              = "esxi"
  disk_provisioning = "thin"
  resource_pool_id  = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id      = data.vsphere_datastore.datastore.id
  host_system_id    = data.vsphere_host.host.id
  remote_ovf_url    = var.esxi_ova_url



  ovf_network_map = {
    "${data.vsphere_network.network.name}" = data.vsphere_network.network.id
    "VM Network"                           = data.vsphere_network.network.id
  }
}


resource "vsphere_virtual_machine" "nested-esxi" {
  name                 = "jcallen-esx"
  datacenter_id        = data.vsphere_datacenter.datacenter.id
  datastore_id         = data.vsphere_ovf_vm_template.esxi.datastore_id
  host_system_id       = data.vsphere_ovf_vm_template.esxi.host_system_id
  resource_pool_id     = data.vsphere_ovf_vm_template.esxi.resource_pool_id
  num_cpus             = data.vsphere_ovf_vm_template.esxi.num_cpus
  num_cores_per_socket = data.vsphere_ovf_vm_template.esxi.num_cores_per_socket
  memory               = data.vsphere_ovf_vm_template.esxi.memory
  guest_id             = data.vsphere_ovf_vm_template.esxi.guest_id
  firmware             = data.vsphere_ovf_vm_template.esxi.firmware
  scsi_type            = data.vsphere_ovf_vm_template.esxi.scsi_type
  nested_hv_enabled    = data.vsphere_ovf_vm_template.esxi.nested_hv_enabled

  dynamic "network_interface" {
    for_each = data.vsphere_ovf_vm_template.esxi.ovf_network_map
    content {
      network_id = network_interface.value
    }
  }
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 0

  ovf_deploy {
    allow_unverified_ssl_cert = false
    remote_ovf_url            = data.vsphere_ovf_vm_template.esxi.remote_ovf_url
    //ip_protocol               = "IPV4"
    //ip_allocation_policy      = "STATIC_MANUAL"
    disk_provisioning         = data.vsphere_ovf_vm_template.esxi.disk_provisioning
    ovf_network_map           = data.vsphere_ovf_vm_template.esxi.ovf_network_map
  }

  vapp {
    properties = {
      "guestinfo.hostname"   = "",
      "guestinfo.ipaddress"  = "",
      "guestinfo.netmask"    = "",
      "guestinfo.gateway"    = "",
      "guestinfo.dns"        = "",
      "guestinfo.domain"     = "",
      "guestinfo.ntp"        = "",
      "guestinfo.ssh"        = "True",
      "guestinfo.password"   = "",
      "guestinfo.createvmfs" = "False",
    }
  }

  lifecycle {
    ignore_changes = [
      annotation,
      disk,
      vapp,
    ]
  }
}
