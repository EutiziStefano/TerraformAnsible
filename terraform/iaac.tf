terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}
provider "azurerm" {
  features {}
  subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}

resource "azurerm_resource_group" "rg" {
  name = "TERRAFORM"
  location = "West Europe"
}


########
# VARS #
########
variable "fe_instances" {
  default = 2
}
variable "be_instances" {
  default = 2
}
variable "mongo_instances" {
  default = 3
}


###########
# NETWORK #
###########

resource "azurerm_virtual_network" "virtualnetwork" {
  name                = "virtualnetwork"
  address_space       = ["172.17.0.0/24"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  
}

resource "azurerm_subnet" "fe-subnet" {
  name                 = "fe-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.virtualnetwork.name
  address_prefixes     = ["172.17.0.0/26"]
}

resource "azurerm_subnet" "be-subnet" {
  name                 = "be-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.virtualnetwork.name
  address_prefixes     = ["172.17.0.64/26"]
}

resource "azurerm_subnet" "mongo-subnet" {
  name                 = "mongo-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.virtualnetwork.name
  address_prefixes     = ["172.17.0.128/26"]
}

################
# BASTION HOST #
################

resource "azurerm_subnet" "bastionsubnet" {
  name                 = "BastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.virtualnetwork.name
  address_prefixes     = ["172.17.0.224/27"]
}

resource "azurerm_public_ip" "bastionPublicIp" {
  name                = "publicIPForBastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "bastion-nic" {
  name                = "bastion-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "bastion_internal"
    subnet_id                     = azurerm_subnet.bastionsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.bastionPublicIp.id
  }
}

resource "azurerm_virtual_machine" "bastion" {
  name                  = "bastion-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.bastion-nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "bastion-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "production"
  }
}

#################################
#                               #
# Open ssh on bastion public ip #
# for this test purpose only    # 
#                               #
#################################
resource "azurerm_network_security_group" "bastionNSG" {
  name                = "bastionNSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface_security_group_association" "NSG_bastionNIC" {
  network_interface_id      = azurerm_network_interface.bastion-nic.id
  network_security_group_id = azurerm_network_security_group.bastionNSG.id
}


####################
# AVAILABILITY SET #
####################

resource "azurerm_availability_set" "avaset" {
  name                = "fenginx-avaset"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = "Production"
  }
}

########
# NICS #
########

resource "azurerm_network_interface" "ethfe" {
  count = var.fe_instances
  name                = "fe-nginx${count.index}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  internal_dns_name_label = "fe-nginx${count.index}"

  ip_configuration {
    name                          = "fe-nginx${count.index}-private"
    subnet_id                     = azurerm_subnet.fe-subnet.id
    private_ip_address_allocation = "dynamic"
  }
}
resource "azurerm_network_interface" "ethbe" {
  count = var.be_instances
  name                = "be-node${count.index}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  internal_dns_name_label = "be-node${count.index}"

  ip_configuration {
    name                          = "be-node${count.index}-private"
    subnet_id                     = azurerm_subnet.be-subnet.id
    private_ip_address_allocation = "dynamic"
  }
}
resource "azurerm_network_interface" "ethmongo" {
  count = var.mongo_instances
  name                = "mongo-${count.index}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  internal_dns_name_label = "mongo-node${count.index}"

  ip_configuration {
    name                          = "mongo${count.index}-private"
    subnet_id                     = azurerm_subnet.mongo-subnet.id
    private_ip_address_allocation = "dynamic"
  }
}


#################
# LOAD BALANCER #
#################

resource "azurerm_public_ip" "pubip" {
 name                         = "publicIPForLB"
 location                     = azurerm_resource_group.rg.location
 resource_group_name          = azurerm_resource_group.rg.name
 allocation_method            = "Static"
}

resource "azurerm_lb" "lb" {
 name                = "loadBalancer"
 location            = azurerm_resource_group.rg.location
 resource_group_name = azurerm_resource_group.rg.name

 frontend_ip_configuration {
   name                 = "publicIPAddress"
   public_ip_address_id = azurerm_public_ip.pubip.id
 }
}

resource "azurerm_lb_backend_address_pool" "lb_backend_address_pool" {
 resource_group_name = azurerm_resource_group.rg.name
 loadbalancer_id     = azurerm_lb.lb.id
 name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "probe" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id = azurerm_lb.lb.id
  name = "tcp_80"
  port = 80
  protocol = "Tcp"
}

resource "azurerm_lb_rule" "rule" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "publicIPAddress"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend_address_pool.id
  probe_id = azurerm_lb_probe.probe.id
}

###################
# FE ASSOCIATIONS #
###################

resource "azurerm_network_interface_backend_address_pool_association" "association2" {
  count = var.fe_instances
  network_interface_id    = azurerm_network_interface.ethfe[count.index].id
  ip_configuration_name   = "fe-nginx${count.index}-private"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.lb_backend_address_pool.id}"
}

#########
# VM FE #
#########

resource "azurerm_virtual_machine" "fe-nginx" {
  count = var.fe_instances
  name                  = "fe-nginx${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [element(azurerm_network_interface.ethfe.*.id, count.index)]
  vm_size               = "Standard_DS1_v2"
  availability_set_id = azurerm_availability_set.avaset.id
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "fe-myosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "fe-nginx${count.index}"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "production"
  }
}


#########
# VM BE #
#########

resource "azurerm_virtual_machine" "be-node" {
  count = var.be_instances
  name                  = "be-node${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [element(azurerm_network_interface.ethbe.*.id, count.index)]
  vm_size               = "Standard_DS1_v2"
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "be-myosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "be-node${count.index}"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "production"
  }
}

############
# VM MONGO #
############

resource "azurerm_virtual_machine" "mongo" {
  count = var.mongo_instances
  name                  = "mongo${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [element(azurerm_network_interface.ethmongo.*.id, count.index)]
  vm_size               = "Standard_DS1_v2"
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "mongo-myosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "mongo${count.index}"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "production"
  }
}


################
# DISCHI MONGO #
################

resource "azurerm_managed_disk" "mongodisk" {
  count = var.mongo_instances
  name                 = "mongo_extra_disk${count.index}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
}

resource "azurerm_virtual_machine_data_disk_attachment" "mongoattach" {
  count = var.mongo_instances
  managed_disk_id    = azurerm_managed_disk.mongodisk[count.index].id
  virtual_machine_id = azurerm_virtual_machine.mongo[count.index].id
  lun                = "10"
  caching            = "ReadWrite"
}

##################
# MONGODB BACKUP #
##################

resource "azurerm_network_interface" "dbbackup-nic" {
  name                = "dbbackup-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "dbbackup_internal"
    subnet_id                     = azurerm_subnet.mongo-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "dbbackup" {
  name                  = "dbbackup"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.dbbackup-nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "dbbackup-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "dbbackup"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "production"
  }
}

resource "azurerm_managed_disk" "backupdisk" {
  name                 = "backup_disk"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 80
}

resource "azurerm_virtual_machine_data_disk_attachment" "backupattach" {
  managed_disk_id    = azurerm_managed_disk.backupdisk.id
  virtual_machine_id = azurerm_virtual_machine.dbbackup.id
  lun                = "10"
  caching            = "ReadWrite"
}

output "instance_ip_addr" {
  value       = azurerm_public_ip.pubip.ip_address
  description = "The public IP address of LoadBalancer."
}
