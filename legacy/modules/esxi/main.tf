resource "vsphere_virtual_machine" "vm" {
  name             = var.name
  resource_pool_id = var.resource_pool
  datastore_id     = var.datastore
  num_cpus         = 16
  memory           = 81920
  guest_id         = var.guest_id

  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 15

  network_interface {
    network_id = var.network
  }
  network_interface {
    network_id = var.network
  }

  //this is so dumb that I have its required to have a disk here

  disk {
    label = "disk0"
    size  = 1
  }

  clone {
    template_uuid = var.template
  }
}

