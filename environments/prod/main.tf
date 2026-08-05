module "rg" {
  source = "../../Modules/azurerm_resource_group"
  rg     = var.rg
}

module "stg" {
  source     = "../../Modules/azurerm_storage_account"
  container = var.container
  depends_on = [module.rg]
  stg        = var.stg
}

module "vnet" {
  source     = "../../Modules/azurerm_virtual_network"
  depends_on = [module.rg]
  vnet       = var.vnet
}

module "subnet" {
  source     = "../../Modules/azurerm_subnet"
  depends_on = [module.rg, module.vnet]
  subnet     = var.subnet
}
