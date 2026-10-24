data "azurerm_client_config" "current" {}

resource "random_string" "kv" {
  length  = 5
  upper   = false
  special = false
}

# Identity the client workload (the VM) uses to reach Key Vault: no passwords or keys on the box.
resource "azurerm_user_assigned_identity" "workload" {
  name                = "id-${var.name_prefix}-workload"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_key_vault" "this" {
  name                       = "kv-${var.name_prefix}-${random_string.kv.result}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = var.purge_protection_enabled
  tags                       = var.tags

  # Lab setting so the GitHub runner can write secrets.
  # Production: private endpoint + firewall rules.
  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

# Pipeline identity can manage secrets...
resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ...the workload can only read them (least privilege).
resource "azurerm_role_assignment" "workload_secrets_user" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

# Azure RBAC can take a minute to propagate; avoids a 403 on first apply.
resource "time_sleep" "rbac_propagation" {
  create_duration = "60s"
  depends_on      = [azurerm_role_assignment.deployer_secrets_officer]
}

# Demo secret. NOTE: its value lands in Terraform state, which is why state is
# private, Entra-auth only, and versioned. Real client secrets would be set out-of-band.
resource "random_password" "demo" {
  length  = 24
  special = true
}

resource "azurerm_key_vault_secret" "demo" {
  name         = "demo-app-secret"
  value        = random_password.demo.result
  key_vault_id = azurerm_key_vault.this.id
  content_type = "demo-only"
  depends_on   = [time_sleep.rbac_propagation]
}
