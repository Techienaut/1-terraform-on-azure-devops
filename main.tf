terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.61"
    }
  }
  backend "azurerm" {
    resource_group_name  = "terraformstate"
    storage_account_name = "tfstate102691266"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }

  required_version = ">= 0.15.4"
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

data "azurerm_client_config" "current" {
}

resource "azurerm_resource_group" "rg-kv" {
  name     = "techienaut-keyvault-rg"
  location = "centralus"
}

resource "azurerm_key_vault" "kv" {
  name                        = "techienaut-keyvault"
  location                    = azurerm_resource_group.rg-kv.location
  resource_group_name         = azurerm_resource_group.rg-kv.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  sku_name                    = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    # application_id = data.azurerm_client_config.current.client_id

    key_permissions = [
      "Get", "Create"
    ]

    secret_permissions = [
      "Get", "Set", "Delete"
    ]

    storage_permissions = [
      "Get"
    ]
  }
}
# data "azurerm_key_valut" "kv" {
#   name = "techienaut-keyvault"
#   resource_group_name = ""
# }

resource "random_password" "vm-password" {
  length  = 16
  special = true
  upper   = true
}

resource "azurerm_key_vault_secret" "vm-secret" {
  name         = "vm-secret"
  key_vault_id = azurerm_key_vault.kv.id
  value        = random_password.vm-password.result
}

output "account_id" {
  value = data.azurerm_client_config.current.client_id
}

resource "azurerm_resource_group" "rg" {
  name     = "tf-on-azure-devops"
  location = "centralus"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "toad-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "sn" {
  name                 = "VM"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_storage_account" "toadstorage" {
  name                     = "toadstorage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    "environment" = "toad-env1"
  }
}

resource "azurerm_network_interface" "vmnic" {
  name                = "toad-vm01-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sn.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "toad-vm01" {
  name                  = "my-toad-vm01"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  network_interface_ids = [azurerm_network_interface.vmnic.id]
  vm_size               = "Standard_B2s"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core-smalldisk"
    version   = "latest"
  }

  storage_os_disk {
    name              = "toad-vm01-os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "toad-vm01"
    admin_username = "toad"
    admin_password = azurerm_key_vault_secret.vm-secret.value
  }

  os_profile_windows_config {
  }
}
