resource "azurerm_network_interface" "app_vm_nic" {
  name                = "${var.app_vm["app_server"].name}-nic"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.app_subnet_id
    private_ip_address_allocation = var.app_vm["app_server"].private_ip_allocation
  }
}


resource "azurerm_linux_virtual_machine" "app_vm" {
  name                = var.app_vm["app_server"].name
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  size                = var.app_vm["app_server"].size
  admin_username      = var.app_vm["app_server"].admin_username
  network_interface_ids = [
    azurerm_network_interface.app_vm_nic.id,
  ]
  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = var.app_vm["app_server"].admin_username
    public_key = file("~/.ssh/id_ed25519.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = var.web_vmss.image_sku
    version   = "latest"
  }

  custom_data = filebase64("${path.module}/cloud-init-app.yaml")
}

resource "azurerm_virtual_machine_extension" "app_vm_ama" {
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.app_vm.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}


resource "azurerm_linux_virtual_machine_scale_set" "web_server_scale_set" {
  name                = var.web_vmss.name
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  sku                 = var.web_vmss.sku
  instances           = var.web_vmss.instances
  admin_username      = var.web_vmss.admin_username

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = var.web_vmss.admin_username
    public_key = file("~/.ssh/id_ed25519.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = var.web_vmss.image_sku
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "${var.web_vmss.name}-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.web_subnet_id

      application_gateway_backend_address_pool_ids = var.application_gateway_backend_address_pool_ids
    }

  }
  custom_data = base64encode(
    templatefile("${path.module}/cloud-init-web.yaml.tftpl", {
      app_vm_private_ip = azurerm_network_interface.app_vm_nic.private_ip_address
    })
  )

  lifecycle {
    ignore_changes = [
      instances
    ]
  }
}


resource "azurerm_virtual_machine_scale_set_extension" "web_vmss_ama" {
  name                         = "AzureMonitorLinuxAgent"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.web_server_scale_set.id
  publisher                    = "Microsoft.Azure.Monitor"
  type                         = "AzureMonitorLinuxAgent"
  type_handler_version         = "1.0"
  auto_upgrade_minor_version   = true
}
