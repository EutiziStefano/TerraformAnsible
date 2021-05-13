# TERRAFORM

## Prerequisiti
- terraform

## Composizione
Uno script iaac.tf che contiene l'infrastruttura da creare, in particolare:
- Il Resource Group
- La Virtual Network
- Le 4 Subnet
- Le NIC
- Il LoadBalancer (con backend,probe,rule)
- L'availability set
- Le VM
- I public ip per LoadBalancer e Bastion
- Dischi aggiuntivi e attachment
- etc.

## Utilizzo
- Loggarsi con azure-cli (vedi ../README.md per un esempio)
- Inserire all'interno dello script l'id della subscription da utilizzare (riga 11)
- (optional) modificare il nome del resource group (riga 15)
- (optional) modificare il numero di nodi di fe/be/db (riga 24/27/30)
- Lanciare il comando inizializzazione:
``` terraform init ```
- (optional) Lanciare il comando plan per verificare l'esecuzione
- Lanciare il comando apply per eseguire la creazione delle risorse:
``` terraform apply ```


## Output
Abbiamo in output l'ip pubblico assegnato al LoadBalancer e questo dovra' essere usato per accedere all'applicazione
