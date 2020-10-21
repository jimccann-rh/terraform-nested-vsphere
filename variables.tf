variable "vsphere_username" {
  type    = string
}

variable "vsphere_password" {
  type    = string
}

variable "vsphere_url" {
  type    = string
  default = "vcenter.sddc-44-236-21-251.vmwarevmc.com"
}

variable "vsphere_datacenter" {
  type    = string
  default = "SDDC-Datacenter"
}

variable "vsphere_cluster" {
  type    = string
  default = "Cluster-1"
}


variable "vsphere_datastore" {
  type    = string
  default = "WorkloadDatastore"
}
variable "vsphere_network" {
  type    = string
  default = "dev-segment"
}
variable "esxi_template_name" {
  type    = string
  default = "esxi-67-template"
}

variable "base_domain" {
  type    = string
  default = "vmc.devcluster.openshift.com"
}
variable "vcsa_hostname" {
  type    = string
  default = "jcallen-vcsa"
}

variable "vcsa_ip_address" {
  type    = string
  default = "172.31.250.99"
}


variable "vcsa_network_prefix" {
  type    = string
  default = "23"
}

variable "vcsa_network_gateway" {
  type    = string
  default = "172.31.250.1"
}

variable "vcsa_password" {
  type    = string
}
