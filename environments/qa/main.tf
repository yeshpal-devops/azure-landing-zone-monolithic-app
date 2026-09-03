module "rg" {
  source = "../../modules/azurerm_resource_group"
  rg     = var.rg
}

module "stg" {
  source     = "../../modules/azurerm_storage_account"
  container  = var.container
  depends_on = [module.rg]
  stg        = var.stg
}

module "vnet" {
  source     = "../../modules/azurerm_virtual_network"
  depends_on = [module.rg]
  vnet       = var.vnet
}

module "subnet" {
  source     = "../../modules/azurerm_subnet"
  depends_on = [module.rg, module.vnet]
  subnet     = var.subnet
}
