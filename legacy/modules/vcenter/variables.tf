/*
variable "esxi_ip_address" {
  type = string
}
*/


variable "vc_hostname" {
  type = string
}
variable "vc_username" {
  type = string
}
variable "vc_password" {
  type = string
}
variable "vc_deployment_network" {
  type = string
}
/*
variable "vc_datacenter" {
  type = list
}
*/
variable "vc_datacenter" {
  type = string
}
variable "vc_datastore" {
  type = string
}

// Cluster
variable "vc_target" {
  type = string
}
/*
variable "vc_target" {
  type = list
}
*/
variable "appliance_deployment_option" {
  type    = string
  default = "small"
}
variable "appliance_name" {
  type = string
}
variable "network_ip_family" {
  type    = string
  default = "ipv4"
}
variable "network_mode" {
  type    = string
  default = "static"
}
variable "network_ip" {
  type = string
}
variable "network_dns_servers" {
  type    = string
  default = "10.0.0.2"
}
variable "network_prefix" {
  type = string
}
variable "network_gateway" {
  type = string
}
variable "network_system_name" {
  type = string
}
variable "os_password" {
  type = string
}
variable "os_ntp_servers" {
  type    = string
  default = "pool.ntp.org"
}
variable "sso_password" {
  type = string
}
variable "sso_domain_name" {
  type    = string
  default = "vsphere.local"
}

variable "vcsa_mount_path" {
  type    = string
  default = "/mnt/esxi/"
}


variable "esxi_root_password" {

type = string
}
