# AUTOMATION TEST

Nel repo sono presenti le istruzioni e gli script per realizzare l'architettura e deployare l'applicazione Mongo_dbs (https://bitbucket.org/panik-code/eng_dhub/src/master/).

L'applicazione viene deployata su infrastruttura Virtuale in cloud Microsoft Azure.

### Obiettivi dell'esercizio:

#### Automatizzare la creazione dell'infrastruttura
L'obiettivo e' stato raggiunto implementando l'automazione tramite Terraform

#### Automatizzare il setup dell'applicazione.
Il forming delle macchine virtuali e la configurazione dell'applicazione e del middleware sono stati automatizzati tramite Ansible

#### Implementare un metodo per il riavvio automatico del servizio in caso di crash
Ho scelto di realizzare questo punto utilizzando Monit, questo, come sistema di monitoraggio attivo, permette di intraprendere azioni di riavvio/ripristino del servizio o puo' essere facilmente integrato con sistemi di trouble ticketing. Anche se in questo semplice caso di test effettua semplicemente il riavvio.

NB: Con questa configurazione alla chiamata http://LOAD_BALANCER_IP/STOP i backend verranno stoppati tutti, in quanto l'nginx redirige la chiamata al prossimo upstream essendo una chiamata GET. Se si vuole evitare questo comportamento va aggiunta la direttiva proxy_next_upstream off;

#### Automatizzare il backup del database
Ho realizzato il backup dei database tramite uno script bash che sfrutta l'utility mongodump. Questo script e' schedulato con crontab per girare ogni notte e salva su un disco aggiuntivo i backup, mantenendo gli ultimi 7 giorni.


## Prerequisiti Generali
Per poter eseguire il codice contenuto in questo repository e' necessario avere una postazione Linux con i seguenti tool installati:

- Terraform (testato su v0.15)
- Azure Client (testato su 2.23.0)
- Ansible (testato su 2.7)
- jq
- ssh-pass

Ovviamente e' necessaria una subscription Azure.

## Idempotenza

I playbook Ansible, cosi' come tutti gli script bash descritti piu avanti, e naturalmente lo script terraform sono idempotenti, possono essere lanciati piu' volte senza causare nessun problema, anche in caso di scaleout dei nodi e' possibile rieseguirli sulla totalita' dei nodi.

PS: attenzione solamente a possibili disservizi nel tempo del riavvio dei servizi, dato che non e' impostato il parametro serial le azioni vengono lanciate contemporaneamente su ogni gruppo di hosts, fare attenzione per la parte mongo non e' possibile inserire il serial perche' la parte di creazione dei replicaset sfrutta il run_once

## Struttura del codice
Il codice di automazione e' diviso in 2 parti:

- IAAC per la costruzione dell'infrastruttura, realizzato con Terraform, si trova nella cartella terraform con un README specifico
- Configurazione del middleware e deploy, realizzato con Ansible, si trova nella cartella ansible con un README specifico

## Architettura
L'architettura e' suddivisa in diversi layer, che corrispondo a relative subnet
Di seguito l'architettura del progetto [Sorgente Draw.io](/draw/architettura.drawio) :

#### LOADBALANCER
E' un Azure LoadBalancer con ip pubblico che bilancia su un availability set formato dai nodi di frontend

#### FRONTEND
Strato formato da reverse proxy Nginx che bilanciano tramite il modulo http_upstream sui be sottostanti

#### BE
E' lo strato applicativo dove gira l'applicazione NodeJS, all'interno dei nodi di BE vi e' anche un router mongos per l'accesso al DB

#### Data
In questo strato sono presenti i nodi che compongono l'istanza del database, piu' un nodo per il backup. I nodi sono dotati di disco aggiuntivo per i dati del database.

### Infrastruttura di test
In questo codice di esempio sono stati impostati il minimo numero di nodi per un HA:
- 2 nodi Frontend
- 2 nodi Backend
- 3 nodi Database con un replicaset a 3 istanze
- 1 nodo Backup
- 1 nodo Bastion

![classic](/images/architettura.jpg)

### Networking
Lo script Terraform crea una VirtualNetwork /24 all'interno della quale vengono ritagliate 4 subnet, corrispondenti ai 4 layer indicati nello schema.

## Prima di Iniziare
Prima di iniziare a lanciare gli script effettuare il login con azure-cli con il metodo preferito, e selezionare la subscription, ad es:

```
az login
az account set --subscription="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```
La subscription deve essere poi riportata anche nello script terraform, leggere README nella cartella terraform

## TODO-Miglioramenti
- Andrebbe gestita meglio l'autenticazione/chiavi di accesso alle VM
- Il servizio andrebbe esposto in HTTPS
- Mettere davanti al loadbalancer un Frontdoor con WebApplicationFirewall e chiudere il loadbalancer all'accesso pubblico
- La connessione in ssh al Bastion va gestita con VPN o private connection
- Mettere autenticazione a Mongo/SSL
- Il codice applicativo deve essere rilasciato su un Artifact Registry dal quale lo script di automazione potra' scaricarlo


