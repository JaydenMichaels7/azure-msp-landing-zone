# Azure MSP Client Landing Zone

A secure, isolated network + compute environment for a managed client, built entirely
with Terraform and deployed by GitHub Actions. One client = one environment folder.

## Architecture

```
Resource group: rg-<client>-<env>
├── networking   VNet 10.10.0.0/16
│                ├── snet-app   (NSG: SSH only from mgmt subnet, deny all other inbound)
│                └── snet-mgmt  (NSG: deny inbound from Internet)
├── security     Key Vault (RBAC mode) + user-assigned managed identity
│                ├── pipeline identity -> Key Vault Secrets Officer
│                └── workload identity -> Key Vault Secrets User (read only)
└── compute      Ubuntu 22.04 VM (Standard_B1s), SSH key only, NO public IP,
                 managed identity attached
```

NSGs are stateful layer-4 packet filters, not firewalls in the Azure Firewall sense.
This design uses them for segmentation; production would add Azure Firewall / private endpoints.

## Setup

**Prereqs:** Azure free account, Azure CLI, Terraform >= 1.6, GitHub account, an SSH key pair
(`ssh-keygen -t ed25519 -f ~/.ssh/msp_lab`).

1. **Create the GitHub repo** `azure-msp-landing-zone` and push this code to it *after* step 3.
2. **Bootstrap once, locally** (creates remote-state storage and the GitHub OIDC identity):
   ```bash
   az login
   cd bootstrap
   cp terraform.tfvars.example terraform.tfvars   # fill in subscription_id and github_org
   terraform init && terraform apply
   terraform output
   ```
3. **Add GitHub repo variables** (Settings > Secrets and variables > Actions > *Variables*):
   `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `TFSTATE_RG`, `TFSTATE_SA`
   (from the bootstrap outputs) and `SSH_PUBLIC_KEY` (contents of `msp_lab.pub`).
   Then create a GitHub **Environment** named exactly `dev`.
4. **Push to `main`.** CI validates and scans, then the apply job deploys.
5. **Prove the PR flow:** branch, change a tag, open a PR, read the plan, merge.

## Pipeline

| Event | What runs |
|---|---|
| Any push | fmt, validate, TFLint, Checkov |
| Pull request to main | the above + `terraform plan` |
| Push to main | the above + `terraform apply` (GitHub Environment `dev`) |
| Manual (Actions tab) | `apply` or `destroy` |

## Cost guardrails

- **Free-account VM offer is 12 months from account creation, new customers only.** After that, the VM bills.
- Set `enable_compute = false` (or run the manual **destroy**) when you are not demoing.
- Create a $5 budget alert in Cost Management.
- No public IP, NAT gateway, Bastion or Azure Firewall: those bill hourly.
- Key Vault bills per operation (pennies at lab volume); it is not a free tier.
- If the free-account OS disk allowance doesn't cover the VM disk, you'll see a small
  disk charge in Cost Management. Check after day 1.

## Known trade-offs (say these in interviews)

- Demo secret value is in Terraform state. State is private, versioned and Entra-auth only; real client secrets would be set out-of-band.
- Key Vault allows public network access so GitHub runners can write secrets. Production: private endpoint + firewall.
- `purge_protection_enabled = false` so the lab can be destroyed. Production: true.
- Checkov runs report-only until findings are triaged.

## Verify it works (no public IP, so use the control plane)

```bash
az vm run-command invoke -g rg-acme-dev -n vm-acme-dev-app \
  --command-id RunShellScript --scripts "hostname && ip a"
```

## Adding another client

Copy `environments/dev` to `environments/<client>-prod`, change `client_name`, the state `key`,
and (for a separate Environment/approval gate) add a matching federated credential in bootstrap.
