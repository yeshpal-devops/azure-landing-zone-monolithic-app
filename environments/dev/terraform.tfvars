rg = {
  dev = {
    name     = "dev-infra"
    location = "West Europe"
  }
}

stg = {
  dev = {
    name                       = "devinfrastorage042026"
    resource_group_name        = "dev-infra"
    location                   = "West Europe"
    account_tier               = "Standard"
    account_replication_type   = "LRS"
    default_action             = "Allow"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
}

container = {
  dev = {
    name                  = "devcontainer"
    storage_account_name  = "devinfrastorage042026"
    container_access_type = "private"
  }
}

vnet = {
  dev = {
    name                = "dev-vnet"
    address_space       = ["10.0.0.0/16"]
    location            = "West Europe"
    resource_group_name = "dev-infra"
  }
}

subnet = {
  dev = {
    name                 = "default"
    resource_group_name  = "dev-infra"
    virtual_network_name = "dev-vnet"
    address_prefixes     = ["10.0.1.0/24"]
    service_endpoints    = []
  }
}
