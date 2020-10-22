# terraform-nested-vsphere


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

