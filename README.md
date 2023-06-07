# terraform-nested-vsphere

Revamp


1. Simplify - use only dhcp for vcenter
2. Use nested content library
3. Use content library for versions: https://download3.vmware.com/software/vmw-tools/items.json

```
$ cat ~/Downloads/items.json|jq '.items[].name'
"Nested_ESXi7.0u3d_Appliance_Template_v1.0"
"Nested_ESXi7.0u3k_Appliance_Template_v1.0"
```
4. Need build numbers to versions table
5. vCenter ? blob, container









### Requirements

- dnf install libnsl


### Running


Yeah this is odd, I would have liked to do a single apply
but the vsphere provider performs the login immediately
and either the new vcsa or esxi node doesn't exist.

So the steps are broken up between two stages `build` and `config`.
This is fragile and a pain, if you have a better way please submit a PR.

```
terraform init stages/build/
terraform init stages/config/
terraform apply -auto-approve stages/build/
terraform apply -auto-approve stages/config/
```


### TODO
- Destroy vcsa appliance when `terraform destroy`
- Enable MAC learn (create a unique port group for nested)


This is need on each physical host if using vSAN

 esxcli system settings advanced set -o /VSAN/FakeSCSIReservations -i 1

