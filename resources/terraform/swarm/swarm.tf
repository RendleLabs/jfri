variable "resource_name_prefix" {}

variable "subscription_id" {}

variable "client_id" {}

variable "client_secret" {}

variable "tenant_id" {}

variable "csr_password" {}

variable "location" {
  default = "northeurope"
}

variable "vm_size" {
  default = "Standard_D1_v2"
}

variable "lb_backend_pool_name" {
  default = "backendPool1"
}

variable "lb_probe_name" {
  default = "tcpProbe"
}

variable "cloudflare_email" {}

variable "cloudflare_token" {}

variable "cloudflare_domain" {}

provider "cloudflare" {
  email = "${var.cloudflare_email}"
  token = "${var.cloudflare_token}"
}

provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

resource "azurerm_resource_group" "swarm" {
  name     = "${var.resource_name_prefix}"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "swarm" {
  name                = "spiffydemo-vn"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.swarm.name}"
}

resource "azurerm_subnet" "swarm" {
  name                 = "spiffydemo-sn"
  resource_group_name  = "${azurerm_resource_group.swarm.name}"
  virtual_network_name = "${azurerm_virtual_network.swarm.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "swarm-manager" {
  name                         = "spiffydemo-ip-manager"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.swarm.name}"
  domain_name_label            = "${var.resource_name_prefix}-manager"
  public_ip_address_allocation = "static"
}

resource "azurerm_public_ip" "swarm-worker" {
  count                        = "2"
  name                         = "spiffydemo-ip-worker-${count.index}"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.swarm.name}"
  domain_name_label            = "${var.resource_name_prefix}-worker-${count.index}"
  public_ip_address_allocation = "dynamic"
}

resource "azurerm_public_ip" "swarm-lb" {
  name                         = "spiffydemo-ip-lb"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.swarm.name}"
  domain_name_label            = "${var.resource_name_prefix}-lb"
  public_ip_address_allocation = "static"
}

resource "azurerm_lb" "swarm" {
  name                = "spiffydemo-lb"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.swarm.name}"

  frontend_ip_configuration {
    name                 = "${var.resource_name_prefix}-lb-fe-ipconfig"
    public_ip_address_id = "${azurerm_public_ip.swarm-lb.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "swarm" {
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.swarm.name}"
  loadbalancer_id     = "${azurerm_lb.swarm.id}"
  name                = "${var.lb_backend_pool_name}"
}

resource "azurerm_network_interface" "swarm-manager" {
  depends_on                = ["azurerm_lb_backend_address_pool.swarm"]
  name                      = "spiffydemo-manager-ni"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.swarm.name}"
  network_security_group_id = "${azurerm_network_security_group.swarm.id}"

  ip_configuration {
    name                                    = "spiffydemo-manager-ipconfig"
    subnet_id                               = "${azurerm_subnet.swarm.id}"
    private_ip_address_allocation           = "dynamic"
    public_ip_address_id                    = "${azurerm_public_ip.swarm-manager.id}"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb.swarm.id}/backendAddressPools/${var.lb_backend_pool_name}"]
  }
}

resource "azurerm_network_interface" "swarm-worker" {
  depends_on                = ["azurerm_lb_backend_address_pool.swarm"]
  count                     = "2"
  name                      = "spiffydemo-worker-ni-${count.index}"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.swarm.name}"
  network_security_group_id = "${azurerm_network_security_group.swarm.id}"

  ip_configuration {
    name                                    = "spiffydemo-worker-ipconfig-${count.index}"
    subnet_id                               = "${azurerm_subnet.swarm.id}"
    private_ip_address_allocation           = "dynamic"
    public_ip_address_id                    = "${element(azurerm_public_ip.swarm-worker.*.id, count.index)}"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb.swarm.id}/backendAddressPools/${var.lb_backend_pool_name}"]
  }
}

resource "azurerm_network_security_group" "swarm" {
  name                = "spiffydemo-nsg"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.swarm.name}"
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
  resource_group_name         = "${azurerm_resource_group.swarm.name}"
  network_security_group_name = "${azurerm_network_security_group.swarm.name}"
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
  resource_group_name         = "${azurerm_resource_group.swarm.name}"
  network_security_group_name = "${azurerm_network_security_group.swarm.name}"
}

resource "azurerm_network_security_rule" "inbound-docker" {
  name                        = "dockertcp"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "2376"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.swarm.name}"
  network_security_group_name = "${azurerm_network_security_group.swarm.name}"
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
  resource_group_name         = "${azurerm_resource_group.swarm.name}"
  network_security_group_name = "${azurerm_network_security_group.swarm.name}"
}

resource "azurerm_storage_account" "swarm" {
  name                = "${var.resource_name_prefix}sysdata"
  resource_group_name = "${azurerm_resource_group.swarm.name}"
  location            = "${var.location}"
  account_type        = "Standard_LRS"

  tags {
    environment = "production"
  }
}

resource "azurerm_storage_container" "swarm" {
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.swarm.name}"
  storage_account_name  = "${azurerm_storage_account.swarm.name}"
  container_access_type = "private"
}

resource "azurerm_availability_set" "swarm" {
  name                = "${var.resource_name_prefix}-availability-set"
  resource_group_name = "${azurerm_resource_group.swarm.name}"
  location            = "${var.location}"
}

resource "azurerm_virtual_machine" "swarm-manager" {
  name                          = "spiffydemo-manager-vm"
  location                      = "${var.location}"
  resource_group_name           = "${azurerm_resource_group.swarm.name}"
  network_interface_ids         = ["${azurerm_network_interface.swarm-manager.id}"]
  vm_size                       = "${var.vm_size}"
  availability_set_id           = "${azurerm_availability_set.swarm.id}"
  delete_os_disk_on_termination = "true"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "managerosdisk1"
    vhd_uri       = "${azurerm_storage_account.swarm.primary_blob_endpoint}${azurerm_storage_container.swarm.name}/managerosdisk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "swarm-manager"
    admin_username = "swarmadmin"
    admin_password = "S3cr3tSqu1rr3l"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/swarmadmin/.ssh/authorized_keys"
      key_data = "${file("~/.ssh/id_rsa.pub")}"
    }
  }

  tags {
    environment = "production"
  }

  provisioner "local-exec" {
    command = "./generate_cert.sh ${azurerm_public_ip.swarm-manager.fqdn} ${azurerm_public_ip.swarm-manager.ip_address} ${azurerm_network_interface.swarm-manager.private_ip_address} ${var.csr_password}"
  }

  provisioner "file" {
    connection {
      type = "ssh"
      user = "swarmadmin"
      host = "${azurerm_public_ip.swarm-manager.fqdn}"
    }

    source      = "./docker-config/"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "swarmadmin"
      host = "${azurerm_public_ip.swarm-manager.fqdn}"
    }

    inline = [
      "curl -fsSL https://get.docker.com/ | sh",
      "sudo usermod -aG docker swarmadmin",
      "sudo docker swarm init --advertise-addr ${azurerm_network_interface.swarm-manager.private_ip_address}",
      "sudo bash /tmp/configure_docker.sh",
    ]
  }

  provisioner "local-exec" {
    command = "./get-token.sh ${azurerm_public_ip.swarm-manager.fqdn}"
  }
}

resource "azurerm_virtual_machine" "swarm-worker" {
  depends_on                    = ["azurerm_virtual_machine.swarm-manager"]
  count                         = "2"
  name                          = "spiffydemo-worker-vm-${count.index}"
  location                      = "${var.location}"
  resource_group_name           = "${azurerm_resource_group.swarm.name}"
  network_interface_ids         = ["${element(azurerm_network_interface.swarm-worker.*.id, count.index)}"]
  vm_size                       = "${var.vm_size}"
  availability_set_id           = "${azurerm_availability_set.swarm.id}"
  delete_os_disk_on_termination = "true"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "worker${count.index}osdisk1"
    vhd_uri       = "${azurerm_storage_account.swarm.primary_blob_endpoint}${azurerm_storage_container.swarm.name}/worker${count.index}osdisk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "swarm-worker-${count.index}"
    admin_username = "swarmadmin"
    admin_password = "S3cr3tSqu1rr3l"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/swarmadmin/.ssh/authorized_keys"
      key_data = "${file("~/.ssh/id_rsa.pub")}"
    }
  }

  tags {
    environment = "production"
  }

  provisioner "file" {
    connection {
      type = "ssh"
      user = "swarmadmin"
      host = "${element(azurerm_public_ip.swarm-worker.*.fqdn, count.index)}"
    }

    source      = "swarm.token"
    destination = "/tmp/swarm.token"
  }

  provisioner "file" {
    connection {
      type = "ssh"
      user = "swarmadmin"
      host = "${element(azurerm_public_ip.swarm-worker.*.fqdn, count.index)}"
    }

    source      = "./docker-config/"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "swarmadmin"
      host = "${element(azurerm_public_ip.swarm-worker.*.fqdn, count.index)}"
    }

    inline = [
      "sudo apt-get update",
      "curl -fsSL https://get.docker.com/ | sh",
      "sudo usermod -aG docker swarmadmin",
      "sudo bash /tmp/configure_docker.sh",
      "sudo docker swarm join --token $(cat /tmp/swarm.token) ${azurerm_network_interface.swarm-manager.private_ip_address}:2377",
    ]
  }
}

resource "azurerm_lb_probe" "swarm" {
  depends_on          = ["azurerm_virtual_machine.swarm-worker"]
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.swarm.name}"
  loadbalancer_id     = "${azurerm_lb.swarm.id}"
  name                = "${var.lb_probe_name}"
  protocol            = "tcp"
  port                = 22
}

resource "azurerm_lb_rule" "swarm-lb-http" {
  depends_on                     = ["azurerm_lb_probe.swarm"]
  location                       = "${var.location}"
  resource_group_name            = "${azurerm_resource_group.swarm.name}"
  loadbalancer_id                = "${azurerm_lb.swarm.id}"
  name                           = "http"
  protocol                       = "tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "${var.resource_name_prefix}-lb-fe-ipconfig"
  probe_id                       = "${azurerm_lb.swarm.id}/probes/${var.lb_probe_name}"
  backend_address_pool_id        = "${azurerm_lb.swarm.id}/backendAddressPools/${var.lb_backend_pool_name}"
}

resource "azurerm_lb_rule" "swarm-lb-https" {
  depends_on                     = ["azurerm_lb_probe.swarm"]
  location                       = "${var.location}"
  resource_group_name            = "${azurerm_resource_group.swarm.name}"
  loadbalancer_id                = "${azurerm_lb.swarm.id}"
  name                           = "https"
  protocol                       = "tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "${var.resource_name_prefix}-lb-fe-ipconfig"
  probe_id                       = "${azurerm_lb.swarm.id}/probes/${var.lb_probe_name}"
  backend_address_pool_id        = "${azurerm_lb.swarm.id}/backendAddressPools/${var.lb_backend_pool_name}"
}

resource "cloudflare_record" "swarm-wildcard" {
  domain = "${var.cloudflare_domain}"
  name   = "*"
  value  = "${azurerm_public_ip.swarm-lb.ip_address}"
  type   = "A"
  ttl    = 120
}

resource "cloudflare_record" "swarm-root" {
  domain  = "${var.cloudflare_domain}"
  name    = "@"
  value   = "${azurerm_public_ip.swarm-lb.ip_address}"
  type    = "A"
  proxied = false
  ttl     = 120
}

output "manager_fqdn" {
  value = "${azurerm_public_ip.swarm-manager.fqdn}"
}

output "manager_ip" {
  value = "${azurerm_public_ip.swarm-manager.ip_address}"
}
