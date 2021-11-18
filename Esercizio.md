# Descrizione esercizio

L'esercizio richiede la creazione di un'infrastruttura di produzione per l'applicazione mongo_dbs.js. 

L'applicazione usa un database MongoDB e necessita dei due package mongodb ed express. Inoltre necessita delle due variabili di ambiente :

- MONGO_URI="mongodb://username:password@hostname:port""
- HTTP_PORT="xxxx"

Una volta avviata si connette al database MongoDB e visualizza l'elenco dei database presenti. 

Chiamando l'applicazione con http://hostname_web:port/STOP se ne simula il crash.

Obiettivo dell'esercizio è:

- Automatizzare la creazione dell'infrastruttura
- Automatizzare il setup dell'applicazione.
- Implementare un metodo per il riavvio automatico del servizio in caso di crash
- Automatizzare il backup del database

L'ouptput dell'esercizio deve essere:

- il codice utilizzato per produrre l'automazione e la configurazione 
- un file (README.md) con una descrizione che consenta di comprendere il codice ed eseguirlo
- un disegno dell'architettura realizzato con Draw.io (https://app.diagrams.net/)

E' possibile usare una qualsiasi piattaforma public cloud ed un qualsiasi linguaggio di programmazione/automazione.

Il tempo per l'esecuzione dell'esercizio è di una settimana a partire dalla ricezione per email.
