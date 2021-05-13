#!/bin/bash 

NODES=`grep -v \\\[ inventory.ini`
MYKEYVAR=`cat ~/.ssh/id_rsa.pub` 

for i in $NODES; do
  echo $MYKEYVAR | sshpass -p 'Password1234!' ssh testadmin@$i -F ssh_config 'cat > .ssh/authorized_keys && chmod 700 .ssh && chmod 600 .ssh/authorized_keys'
done
