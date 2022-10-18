#!/bin/bash

# Definir subscription e região 

az account set -s "$az_subscription"
az configure --defaults location=$az_region

# Criar resource group

az group create -n ${az_project}-rg -l eastus

# Criar VNET

az network vnet create \
    --resource-group ${az_project}-rg \
    --name ${az_project}-vnet \
    --address-prefix 192.168.0.0/16 \
    --subnet-name ${az_project}-subnet \
    --subnet-prefix 192.168.0.0/16

# Criar NSG

az network nsg create \
    --resource-group ${az_project}-rg \
    --name ${az_project}-nsg

az network nsg rule create \
    --resource-group ${az_project}-rg \
    --nsg-name ${az_project}-nsg \
    --name ${az_project}-nsg-ssh \
	--source-address-prefixes ${az_public_access_cidrs} \
    --protocol tcp \
    --priority 1000 \
    --destination-port-range 22 \
    --access allow

az network nsg rule create \
    --resource-group ${az_project}-rg \
    --nsg-name ${az_project}-nsg \
    --name ${az_project}-nsg-web \
	--source-address-prefixes ${az_public_access_cidrs} \
    --protocol tcp \
    --priority 1001 \
    --destination-port-range 6443 443 80 \
    --access allow


az network vnet subnet update \
    -g ${az_project}-rg \
    -n ${az_project}-subnet \
    --vnet-name ${az_project}-vnet \
    --network-security-group ${az_project}-nsg
	
# Criar VM

az vm create -n ${az_project}-vm -g ${az_project}-rg \
--image CentOS \
--vnet-name ${az_project}-vnet --subnet ${az_project}-subnet \
--admin-username azureuser \
--generate-ssh-keys \
--size ${az_vm_size} \
--nsg ${az_project}-nsg \
--os-disk-size-gb ${az_vm_disk_size_gb} \
--public-ip-sku Standard --no-wait

# Criar LB

az network public-ip create \
    --resource-group ${az_project}-rg \
    --name ${az_project}-ip \
    --sku Standard \
    --dns-name ${az_project}

az network lb create \
    --resource-group ${az_project}-rg \
    --name ${az_project}-lb \
    --sku Standard \
    --public-ip-address ${az_project}-ip \
    --frontend-ip-name ${az_project}-ip \
    --backend-pool-name ${az_project}-be-pool     

az network lb probe create \
    --resource-group ${az_project}-rg \
    --lb-name ${az_project}-lb \
    --name ${az_project}-web-probe \
    --protocol tcp \
    --port 6443   

az network lb probe create \
    --resource-group ${az_project}-rg \
    --lb-name ${az_project}-lb \
    --name ${az_project}-web2-probe \
    --protocol tcp \
    --port 443   

az network lb probe create \
    --resource-group ${az_project}-rg \
    --lb-name ${az_project}-lb \
    --name ${az_project}-web3-probe \
    --protocol tcp \
    --port 80   

az network lb rule create \
    --resource-group ${az_project}-rg \
    --lb-name ${az_project}-lb \
    --name ${az_project}-lb-rule-6443 \
    --protocol tcp \
    --frontend-port 6443 \
    --backend-port 6443 \
    --frontend-ip-name ${az_project}-ip \
    --backend-pool-name ${az_project}-be-pool  \
    --probe-name ${az_project}-web-probe \
    --disable-outbound-snat true \
    --idle-timeout 15 \
    --enable-tcp-reset true

az network lb rule create \
    --resource-group ${az_project}-rg \
    --lb-name ${az_project}-lb \
    --name ${az_project}-lb-rule-443 \
    --protocol tcp \
    --frontend-port 443 \
    --backend-port 443 \
    --frontend-ip-name ${az_project}-ip \
    --backend-pool-name ${az_project}-be-pool  \
    --probe-name ${az_project}-web2-probe \
    --disable-outbound-snat true \
    --idle-timeout 15 \
    --enable-tcp-reset true

az network lb rule create \
    --resource-group ${az_project}-rg \
    --lb-name ${az_project}-lb \
    --name ${az_project}-lb-rule-80 \
    --protocol tcp \
    --frontend-port 80 \
    --backend-port 80 \
    --frontend-ip-name ${az_project}-ip \
    --backend-pool-name ${az_project}-be-pool  \
    --probe-name ${az_project}-web3-probe \
    --disable-outbound-snat true \
    --idle-timeout 15 \
    --enable-tcp-reset true

az network nic ip-config address-pool add \
    --address-pool ${az_project}-be-pool \
    --ip-config-name ipconfig${az_project}-vm \
    --nic-name ${az_project}-vmVMNic \
    --resource-group ${az_project}-rg \
    --lb-name ${az_project}-lb

vmIP=`az vm list-ip-addresses -g ${az_project}-rg -n ${az_project}-vm | grep ipAddress | cut -d ":" -f 2 | sed 's/"//' | sed 's/",//'`
