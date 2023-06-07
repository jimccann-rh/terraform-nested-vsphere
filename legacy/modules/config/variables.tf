variable "esxi_ip_address" {
  type = string
}
variable "network_system_name" {
  type = string
}
variable "sso_password" {
  type = string
}
variable "sso_domain_name" {
  type    = string
  default = "vsphere.local"
}
variable "esxi_root_password" {

type = string
}
