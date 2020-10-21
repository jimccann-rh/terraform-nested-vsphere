variable "name" {
  type    = string
  default = "esxi"
}

variable "resource_pool" {
  type = string
}

/*
variable "folder" {
  type = string
}
*/

variable "datastore" {
  type = string
}

variable "network" {
  type = string
}

variable "datacenter" {
  type = string
}

variable "template" {
  type = string
}

variable "guest_id" {
  type = string
}

