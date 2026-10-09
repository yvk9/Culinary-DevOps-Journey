resource "azurerm_mssql_server" "sqlsrv" {
  name                                         = var.spec.name
  resource_group_name                          = local.rg_name
  location                                     = local.region
  administrator_login                          = var.spec.administrator_login
  administrator_login_password                 = var.secret
  connection_policy                            = var.spec.connection_policy
  minimum_tls_version                          = "1.2"
  outbound_network_restriction_enabled         = false
  primary_user_assigned_identity_id            = null
  public_network_access_enabled                = false
  transparent_data_encryption_key_vault_key_id = var.cmk_id
  version                                      = var.spec.version
  express_vulnerability_assessment_enabled     = true
  tags                                         = var.tags

  azuread_administrator {
    azuread_authentication_only = false
    login_username              = var.spec.azuread_administrator
    object_id                   = var.spec.object_id
    tenant_id                   = "63761141-fb93-4151-b3bd-97196c9aafe6"
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_private_endpoint" "sqlsrv" {
  name                = "pep-${var.spec.name}"
  resource_group_name = azurerm_mssql_server.sqlsrv.resource_group_name
  location            = local.region
  subnet_id           = var.pep_snet_id
  private_service_connection {
    name                           = var.spec.name
    private_connection_resource_id = azurerm_mssql_server.sqlsrv.id
    subresource_names              = ["SqlServer"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = var.spec.dns_zone
    private_dns_zone_ids = var.dns_zone_id
  }
  tags = var.tags
  timeouts {
    create = "30m"
    update = "30m"
    read   = "30m"
    delete = "30m"
  }

  depends_on = [azurerm_mssql_server.sqlsrv]
}

resource "azurerm_mssql_server_microsoft_support_auditing_policy" "default" {
  enabled                = true
  log_monitoring_enabled = true
  server_id              = azurerm_mssql_server.sqlsrv.id
  depends_on             = [azurerm_mssql_server.sqlsrv]
}

resource "azurerm_mssql_server_transparent_data_encryption" "default" {
  server_id        = azurerm_mssql_server.sqlsrv.id
  key_vault_key_id = var.cmk_id
  depends_on       = [azurerm_mssql_server.sqlsrv]
}

resource "azurerm_mssql_server_extended_auditing_policy" "default" {
  enabled                = true
  log_monitoring_enabled = true
  server_id              = azurerm_mssql_server.sqlsrv.id
  depends_on             = [azurerm_mssql_server.sqlsrv]
}

resource "azurerm_mssql_server_security_alert_policy" "default" {
  resource_group_name = local.rg_name
  server_name         = var.spec.name
  state               = "Enabled"
  depends_on          = [azurerm_mssql_server.sqlsrv]
}
