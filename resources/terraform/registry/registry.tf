variable "resource_name_prefix" {}

variable "subscription_id" {}

variable "client_id" {}

variable "client_secret" {}

variable "tenant_id" {}

variable "location" {
  default = "northeurope"
}

variable "vm_size" {
  default = "Standard_D1_v2"
}

variable "cloudflare_email" {}

variable "cloudflare_token" {}

variable "cloudflare_domain" {}

provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

provider "cloudflare" {
  email = "${var.cloudflare_email}"
  token = "${var.cloudflare_token}"
}

resource "azurerm_resource_group" "spiffyregistry" {
  name     = "${var.resource_name_prefix}"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "spiffyregistry" {
  name                = "spiffyregistry-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.spiffyregistry.name}"
}

resource "azurerm_subnet" "spiffyregistry" {
  name                 = "spiffyregistry-subnet"
  resource_group_name  = "${azurerm_resource_group.spiffyregistry.name}"
  virtual_network_name = "${azurerm_virtual_network.spiffyregistry.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "spiffyregistry" {
  name                         = "spiffyregistry-ip"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.spiffyregistry.name}"
  domain_name_label            = "${var.resource_name_prefix}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "spiffyregistry" {
  name                      = "spiffyregistry-ni"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.spiffyregistry.name}"
  network_security_group_id = "${azurerm_network_security_group.spiffyregistry.id}"

  ip_configuration {
    name                          = "spiffyregistry-configuration1"
    subnet_id                     = "${azurerm_subnet.spiffyregistry.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.spiffyregistry.id}"
  }
}

resource "azurerm_network_security_group" "spiffyregistry" {
  name                = "spiffyregistry-nsg"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.spiffyregistry.name}"
}

resource "azurerm_network_security_rule" "inbound-http" {
  name                        = "http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.spiffyregistry.name}"
  network_security_group_name = "${azurerm_network_security_group.spiffyregistry.name}"
}

resource "azurerm_network_security_rule" "inbound-https" {
  name                        = "https"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.spiffyregistry.name}"
  network_security_group_name = "${azurerm_network_security_group.spiffyregistry.name}"
}

resource "azurerm_network_security_rule" "inbound-registry" {
  name                        = "registry"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5000"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.spiffyregistry.name}"
  network_security_group_name = "${azurerm_network_security_group.spiffyregistry.name}"
}

resource "azurerm_network_security_rule" "inbound-ssh" {
  name                        = "ssh"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.spiffyregistry.name}"
  network_security_group_name = "${azurerm_network_security_group.spiffyregistry.name}"
}

resource "azurerm_storage_account" "spiffyregistry" {
  name                = "${var.resource_name_prefix}sysdata"
  resource_group_name = "${azurerm_resource_group.spiffyregistry.name}"
  location            = "${var.location}"
  account_type        = "Standard_LRS"

  tags {
    environment = "production"
  }
}

resource "azurerm_storage_container" "spiffyregistry" {
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.spiffyregistry.name}"
  storage_account_name  = "${azurerm_storage_account.spiffyregistry.name}"
  container_access_type = "private"
}

resource "azurerm_virtual_machine" "spiffyregistry" {
  name                          = "spiffyregistry-vm"
  location                      = "${var.location}"
  resource_group_name           = "${azurerm_resource_group.spiffyregistry.name}"
  network_interface_ids         = ["${azurerm_network_interface.spiffyregistry.id}"]
  vm_size                       = "${var.vm_size}"
  delete_os_disk_on_termination = "true"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "spiffyregistryosdisk1"
    vhd_uri       = "${azurerm_storage_account.spiffyregistry.primary_blob_endpoint}${azurerm_storage_container.spiffyregistry.name}/spiffyregistryosdisk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "spiffyregistry"
    admin_username = "spiffyadmin"
    admin_password = "S3cr3tSqu1rr3l"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/spiffyadmin/.ssh/authorized_keys"
      key_data = "${file("~/.ssh/id_rsa.pub")}"
    }
  }

  tags {
    environment = "production"
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "spiffyadmin"
      host = "${azurerm_public_ip.spiffyregistry.fqdn}"
    }

    inline = [
      "curl -fsSL https://get.docker.com/ | sh",
      "sudo usermod -aG docker spiffyadmin",
    ]
  }
}

resource "cloudflare_record" "spiffyregistry" {
  domain = "${var.cloudflare_domain}"
  name   = "registry"
  value  = "${azurerm_public_ip.spiffyregistry.ip_address}"
  type   = "A"
  ttl    = 3600
}
