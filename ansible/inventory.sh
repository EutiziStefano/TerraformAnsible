#!/bin/bash

> inventory.ini
> ssh_config

RG=TERRAFORM

az vm list -g $RG | jq '.[].name'| sed 's/\"//g' | sort > /tmp/list

echo "Host 172.17.0.*"  >> ssh_config
echo "  StrictHostKeyChecking no" >> ssh_config
echo "  UserKnownHostsFile /dev/null" >> ssh_config

#BASTION
vm=`grep bastion /tmp/list`
echo "[bastion]" >> inventory.ini
echo $vm
IPBASTION=`az vm list-ip-addresses -g $RG -n $vm | jq '.[0].virtualMachine.network.publicIpAddresses[0].ipAddress' | sed 's/\"//g'`
echo $IPBASTION >> inventory.ini
echo "Host $IPBASTION" >> ssh_config
echo "  User testadmin" >> ssh_config
echo "  StrictHostKeyChecking no" >> ssh_config
echo "  UserKnownHostsFile /dev/null" >> ssh_config



# FE
VMLIST=`grep fe /tmp/list`
echo "[fe]" >> inventory.ini
for vm in `echo $VMLIST`; do
  echo $vm
  IP=`az vm list-ip-addresses -g $RG -n $vm | jq '.[0].virtualMachine.network.privateIpAddresses[0]' | sed 's/\"//g'`
  echo $IP >> inventory.ini
  echo "Host $IP" >> ssh_config
  echo "  ProxyJump $IPBASTION" >> ssh_config
done

# BE
VMLIST=`grep be /tmp/list`
echo "[be]" >> inventory.ini
for vm in `echo $VMLIST`; do
  echo $vm
  IP=`az vm list-ip-addresses -g $RG -n $vm | jq '.[0].virtualMachine.network.privateIpAddresses[0]' | sed 's/\"//g'`
  echo $IP >> inventory.ini
  echo "Host $IP" >> ssh_config
  echo "  ProxyJump $IPBASTION" >> ssh_config
done

# MONGO
VMLIST=`grep mongo /tmp/list`
echo "[mongo]" >> inventory.ini
for vm in `echo $VMLIST`; do
  echo $vm
  IP=`az vm list-ip-addresses -g $RG -n $vm | jq '.[0].virtualMachine.network.privateIpAddresses[0]' | sed 's/\"//g'`
  echo $IP >> inventory.ini
  echo "Host $IP" >> ssh_config
  echo "  ProxyJump $IPBASTION" >> ssh_config
done


# MONGOBACKUP
VMLIST=`grep dbbackup /tmp/list`
echo "[dbbackup]" >> inventory.ini
for vm in `echo $VMLIST`; do
  echo $vm
  IP=`az vm list-ip-addresses -g $RG -n $vm | jq '.[0].virtualMachine.network.privateIpAddresses[0]' | sed 's/\"//g'`
  echo $IP >> inventory.ini
  echo "Host $IP" >> ssh_config
  echo "  ProxyJump $IPBASTION" >> ssh_config
done



