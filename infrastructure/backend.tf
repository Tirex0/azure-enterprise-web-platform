terraform {
  backend "azurerm" {
    resource_group_name  = "sharedservices-rg"
    storage_account_name = "tfstatec3h48"
    container_name       = "terraform-state"
    key                  = "dev.terraform.tfstate"

    use_oidc         = true
    use_azuread_auth = true
    tenant_id        = "be0089ff-e1df-4984-b4c7-62d8a5ed2101"
    client_id        = "4fd39b82-5a98-493a-af34-6903412a89ad"
  }
}
