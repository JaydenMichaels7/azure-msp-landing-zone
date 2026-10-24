terraform {
  # resource_group_name and storage_account_name are passed at init time
  # (-backend-config) so nothing environment-specific is hard-coded.
  backend "azurerm" {
    container_name   = "tfstate"
    key              = "dev.terraform.tfstate"
    use_azuread_auth = true
  }
}
