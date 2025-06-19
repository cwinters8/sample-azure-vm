# Sample Azure VM

Minimal Terraform configuration to provision:

- Basic Azure networking stack
- Linux Virtual Machine
- SSH keys, stored in Key Vault
- Bastion host to connect to the VM

You can use the generated key and bastion host to connect to the VM via the
console. See the [Azure documentation] for more details.

## Prerequisites

- [Azure CLI] installed and authenticated (`az login`)
- [terraform]
- Some Azure resources manually provisioned:
  - Resource group
  - Storage account
  - Storage container

## Run

To plan and apply in one step:

```sh
terraform apply
```

## Teardown

To prevent accruing a higher Azure bill than necessary, delete provisioned resources when you're done:

```sh
terraform destroy
```

[Azure CLI]: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
[terraform]: https://developer.hashicorp.com/terraform/install
[Azure documentation]: https://learn.microsoft.com/en-us/azure/bastion/bastion-connect-vm-ssh-linux#ssh-private-key-authentication---azure-key-vault
