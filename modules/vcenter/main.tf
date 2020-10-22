resource "local_file" "vcenter_config" {
  content = templatefile("${path.module}/config.tpl", {

    vc_hostname                 = var.vc_hostname,
    vc_username                 = var.vc_username,
    vc_password                 = var.vc_password,
    vc_deployment_network       = var.vc_deployment_network,
    vc_datacenter               = var.vc_datacenter,
    vc_datastore                = var.vc_datastore,
    vc_target                   = var.vc_target,
    appliance_deployment_option = var.appliance_deployment_option,
    appliance_name              = var.appliance_name,
    network_ip_family           = var.network_ip_family,
    network_mode                = var.network_mode,
    network_ip                  = var.network_ip,
    network_dns_servers         = var.network_dns_servers,
    network_prefix              = var.network_prefix,
    network_gateway             = var.network_gateway,
    network_system_name         = var.network_system_name,
    os_password                 = var.os_password,
    os_ntp_servers              = var.os_ntp_servers,
    sso_password                = var.sso_password,
    sso_domain_name = var.sso_domain_name }

  )
  filename = "${path.module}/config.json"

  provisioner "local-exec" {

    command = "${var.vcsa_mount_path}/vcsa-cli-installer/lin64/vcsa-deploy install --terse --accept-eula --acknowledge-ceip --no-ssl-certificate-verification ${path.module}/config.json"

    //command = "${var.vcsa_mount_path}/vcsa-cli-installer/lin64/vcsa-deploy install --verify-template-only --terse --accept-eula --acknowledge-ceip --no-ssl-certificate-verification ${path.module}/config.json"
  }
}


/*
provider "vsphere" {
  user                 = "administrator@${var.sso_domain_name}"
  password             = var.sso_password
  vsphere_server       = var.network_system_name
  allow_unverified_ssl = true

  alias = "nested"
}

resource "vsphere_datacenter" "nested_datacenter" {
  //provider = vsphere.nested
  name = "SDDC-Datacenter"

  depends_on = [local_file.vcenter_config]
}

resource "vsphere_compute_cluster" "nested_cluster" {
  //provider = vsphere.nested
  name                 = "Cluster-1"
  datacenter_id        = vsphere_datacenter.nested_datacenter.id
  drs_enabled          = true
  drs_automation_level = "fullyAutomated"
}


resource "vsphere_host" "h1" {
  //provider = vsphere.nested
  hostname = var.esxi_ip_address
  username = "root"
  password = var.esxi_root_password
  cluster  = vsphere_compute_cluster.nested_cluster.id
}
*/


