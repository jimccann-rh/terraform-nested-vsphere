// https://github.com/s3fs-fuse/s3fs-fuse/wiki/Non-Amazon-S3


variable "vcsa_config_json" {
  type = string
}
variable "vcsa_mount_path" {
  type = string
}

locals {
  config_file_path  = "${path.module}/config.json"
}

resource "local_file" "vcsa_config_file" {
  content  = var.vcsa_config_json
  filename = local.config_file_path
}

resource "null_resource" "vcsa-cli-installer" {
  provisioner "local-exec" {
    command = "${var.vcsa_mount_path}/vcsa-cli-installer/lin64/vcsa-deploy install --terse --accept-eula --acknowledge-ceip --no-ssl-certificate-verification ${local.config_file_path}"
  }
}