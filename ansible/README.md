#Ansible playbooks
Questa cartella contiene i playbook ansible e le configurazioni per realizzare l'installazione del middleware e il deploy dell'applicazione.
## Prerequisiti
1. Loggarsi con azure-cli (vedi ../README.md per un esempio)
2. Generare l'inventory e l'ssh_config per il jump della connessione ai nodi sul bastion, lanciare lo script `./inventory.sh`
3. Scambiare chiave SSH per la connessione ai nodi, c'e' uno script apposito key_exchange.sh per farlo se il login e' stato lasciato con password e non con chiave alla creazione delle VM

# Organizzazione dei playbook
I playboook sono organizzati in 4 parti:
- Preparazione dei nodi FE
- Configurazione Middleware FE
- Preparazione dei nodi BE
- Configurazione Applicativo BE
- Preparazione nodi Database
- Configurazione nodi Database
- Configurazione Mongos sui nodi BE e nodo di Backup
- Configurazione del Backup

Ad ognuno di questi passaggi corrisponde un file yaml di task all'interno della cartella atomic che poi viene incluso nel playbook generale

## Esecuzione dei playbook

1. Eseguire step dei Prerequisiti
2. Lanciare il playbook con lo script `./run_playbook.sh`


## Ulteriori dettagli

### inventory.sh
Questo script tramite il client az ricava la lista delle macchine virtuali e costruisce l'inventory per ansible in formato ini.

Genera inoltre un file ssh_config che corrisponde al file di configurazione ssh, che di solito si trova in ~/.ssh/config, il quale verra' usato durante l'esecuzione dei playbook e configura le connessioni ai nodi passando per il bastion, nonche' disabilita alcune funzioni di sicurezza di ssh (StrictHostKeyChecking,UserKnownHostsFile) che potrebbero dare problemi durante i test qualora le macchine vengano distrutte e ricreate.

Sempre tramite az prende inoltre l'ip pubblico del bastion da impostare come ProxyJump.

### key_exchange.sh
Questo script si occupa di copiare la chiave ssh dell'utente corrente all'interno di tutte le macchine che sono state discoverate dall'inventory.sh
Contiene all'interno la password impostata tramite terraform e la passa tramite ssh-pass per non doverla inserire allo scambio della chiave.
A questo punto la password puo' essere cambiata o disabilitato il login con password, l'accesso avverra' tramite chiave.

### run_playbook.sh
Si occupa semplicemente di lanciare il playbook passando tutti i parametri necessari.
