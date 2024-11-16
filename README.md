# LAMP Manager Script

![Versione](https://img.shields.io/badge/Versione-1.4-blue)
![Testato su](https://img.shields.io/badge/Testato%20su-Ubuntu%2022.04%20LTS-violet)
![Licenza](https://img.shields.io/badge/Licenza-MIT-green)



```
   ██▓    ▄▄▄       ███▄ ▄███▓ ██▓███   ███▄ ▄███▓ ███▄    █   ▄████  ██▀███
  ▓██▒   ▒████▄    ▓██▒▀█▀ ██▒▓██░  ██▒▓██▒▀█▀ ██▒ ██ ▀█   █  ██▒ ▀█▒▓██ ▒ ██▒
  ▒██░   ▒██  ▀█▄  ▓██    ▓██░▓██░ ██▓▒▓██    ▓██░▓██  ▀█ ██▒▒██░▄▄▄░▓██ ░▄█ ▒
  ▒██░   ░██▄▄▄▄██ ▒██    ▒██ ▒██▄█▓▒ ▒▒██    ▒██ ▓██▒  ▐▌██▒░▓█  ██▓▒██▀▀█▄
  ░██████▒▓█   ▓██▒▒██▒   ░██▒▒██▒ ░  ░▒██▒   ░██▒▒██░   ▓██░░▒▓███▀▒░██▓ ▒██▒
  ░ ▒░▓  ░▒▒   ▓▒█░░ ▒░   ░  ░▒▓▒░ ░  ░░ ▒░   ░  ░░ ▒░   ▒ ▒  ░▒   ▒ ░ ▒▓ ░▒▓░
  ░ ░ ▒  ░ ▒   ▒▒ ░░  ░      ░░▒ ░     ░  ░      ░░ ░░   ░ ▒░  ░   ░   ░▒ ░ ▒░
    ░ ░    ░   ▒   ░      ░   ░░       ░      ░      ░   ░ ░ ░ ░   ░   ░░   ░
      ░  ░     ░  ░       ░                   ░            ░       ░    ░
```

Script Bash per automatizzare l'installazione e la configurazione di un server LAMP (Linux, Apache, MySQL, PHP) su Ubuntu 22.04 LTS. Consente di configurare rapidamente un ambiente di hosting completo con supporto per siti WordPress, gestione dei permessi e sicurezza MySQL di base.

## Funzionalità

- **Installazione Server LAMP**: Installa e configura Apache, MySQL, PHP e Certbot con un semplice comando.
- **Configurazione VirtualHost Apache**: Crea VirtualHost per siti specifici, includendo la gestione dei permessi e l'aggiunta del dominio al file `/etc/hosts`.
- **Configurazione di un sito WordPress**: Scarica, decomprime e configura WordPress con i permessi di sicurezza adeguati.
- **Gestione Permessi WordPress**: Configura correttamente i permessi di file e cartelle per una maggiore sicurezza.
- **Disinstallazione di un sito**: Rimuove un sito specifico, inclusi il VirtualHost Apache, il database MySQL e i file del sito.
- **Certificati SSL**: Installa e configura Certbot per la gestione automatizzata dei certificati SSL.
- **Lista Siti Installati**: Visualizza un elenco dei siti installati e i relativi percorsi.
- **Sicurezza MySQL**: Include l'installazione e la configurazione di base di MySQL, con l'opzione di configurare una password sicura per l'utente `root`.

## Requisiti

- **Sistema operativo**: Ubuntu 22.04 LTS (o versioni compatibili)
- **Privilegi di root**: È necessario eseguire lo script con privilegi di root

## Istruzioni per l'uso

1. **Clona o scarica lo script**:  
   ```bash
   git clone https://github.com/tuo-utente/webserver-manager.git
   cd webserver-manager

2. Assegna i permessi di esecuzione allo script:

   ```bash
   sudo chown root:root webserver_manager.sh
   sudo chmod 700 webserver_manager.sh
   ```

3. Esegui lo script:
   
   ```bash
   sudo ./webserver_manager.sh
   ```

## Menu Principale

Lo script offre un'interfaccia a menu con le seguenti opzioni:

1. Installa Server LAMP:
   Installa Apache, MySQL, PHP e Certbot con le configurazioni necessarie.

2. Crea un sito:
    Configura un VirtualHost Apache, crea un database MySQL per il dominio specificato e, se richiesto, scarica e configura WordPress.

3. Disinstalla sito:
    Rimuove un VirtualHost Apache, il database MySQL e i file del sito specificato.

4. Imposta permessi WP:
    Configura correttamente i permessi di sicurezza per un sito WordPress.

5. Genera certificato SSL:
    Installa e configura un certificato SSL per un dominio specifico.

6. Lista siti installati:
    Visualizza un elenco dei siti installati.

7. Esci:
    Termina l'esecuzione dello script.

## Dettagli Tecnici

- Apache: Abilitazione automatica di mod_rewrite e configurazione del firewall con ufw.
- MySQL: Configurazione della password root, esecuzione automatica di mysql_secure_installation, e - creazione di database e utenti.
- PHP: Verifica della versione di PHP installata e installazione dei moduli necessari.
- Certbot: Installazione per la gestione automatizzata di certificati SSL.

## Sicurezza

- Lo script controlla che venga eseguito con privilegi di root e che i permessi siano corretti (700) per garantire la sicurezza.
- MySQL viene configurato con password sicure e vengono eseguite operazioni di sicurezza di base per limitare le vulnerabilità.

## Note Importanti

- Esegui lo script con cautela: Effettua sempre un backup dei dati importanti prima di eseguire script di configurazione automatizzati.
- Limitazioni: Lo script è progettato per essere eseguito su un sistema Ubuntu 22.04 LTS. Potrebbe non funzionare correttamente su altre distribuzioni o versioni di Ubuntu.

## Contribuzione

Se desideri contribuire a migliorare questo script, sentiti libero di creare una fork del progetto e inviare una pull request. Ogni feedback e suggerimento è ben accetto!

## Autore

Creato da [Enrico Marogna](https://enricomarogna.com/)

## Licenza

Distribuito sotto la licenza MIT. Consulta il file LICENSE per maggiori dettagli.
Puoi modificarlo ulteriormente per aggiungere dettagli specifici o link utili.

# Supporta lo Sviluppo
Puoi supportare lo sviluppo di questo progetto con una donazione su Ko-fi.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/W7W8166X59)
