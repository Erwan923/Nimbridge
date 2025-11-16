resource "azurerm_resource_group" "nimbridge" {
  name     = "rg-nimbridge"
  location = var.location
}

resource "azurerm_container_registry" "nimbridge" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.nimbridge.name
  location            = azurerm_resource_group.nimbridge.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_log_analytics_workspace" "nimbridge" {
  name                = "log-nimbridge"
  location            = azurerm_resource_group.nimbridge.location
  resource_group_name = azurerm_resource_group.nimbridge.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "nimbridge" {
  name                       = "cae-nimbridge"
  location                   = azurerm_resource_group.nimbridge.location
  resource_group_name        = azurerm_resource_group.nimbridge.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.nimbridge.id
}

output "acr_login_server" {
  value = azurerm_container_registry.nimbridge.login_server
}

output "acr_username" {
  value = azurerm_container_registry.nimbridge.admin_username
}

output "acr_password" {
  value     = azurerm_container_registry.nimbridge.admin_password
  sensitive = true
}
