#!/bin/bash

# Creato da: Enrico Marogna - https://enricomarogna.com
# Versione 1.8.0
# Testato su Ubuntu 22.04 LTS
# ---------------------------------------------------------
# Questo script automatizza l'installazione e la configurazione di un server LAMP (Linux, Apache, MySQL, PHP) su un sistema Ubuntu.
# Permette la creazione di VirtualHost Apache, la gestione di un database MySQL per un sito web, e include l'opzione per
# configurare un sito WordPress con permessi di sicurezza appropriati. Controlla e imposta le configurazioni necessarie,
# come i permessi di file e l'uso di moduli Apache. Include anche una gestione basilare della sicurezza MySQL.
# È consigliato eseguire lo script con privilegi di root per garantire che tutte le operazioni vengano effettuate correttamente:
# "sudo chown root:root webserver_manager.sh && sudo chmod 700 webserver_manager.sh"
# Per eseguire lo script, digitare "sudo ./webserver_manager.sh"
# ---------------------------------------------------------

# COLORS
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
PURPLE='\033[35m'
RESET='\033[0m'

# Funzione per mostrare il menu
mostra_menu() {
  ## Se lo script non è lanciato come root, esci
  if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Devi eseguire lo script come root${RESET}"
    exit 1
  fi

  # se il file stesso non non è di proprietà di root e non ha i permessi 700, esci
  if [ "$(stat -c %U $0)" != "root" ] || [ "$(stat -c %a $0)" != "700" ]; then
    path_script=$(realpath $0)
    echo -e "${RED}Lo script deve essere di proprietà di root e avere i permessi 700 per essere eseguito in sicurezza:${RESET}"
    echo -e "Esegui: ${BLUE}sudo chown root:root $path_script && sudo chmod 700 $path_script${RESET}"
    exit 1
  fi

  echo -e "${PURPLE}"
  echo -e "========================================================================================"
  echo -e "                       Web Server Manager - Gestione del server LAMP                    "
  echo -e "========================================================================================"
  echo -e "1) Installa Server LAMP    - Installa Apache, MySQL, PHP e Certbot"
  echo -e "2) Installa un sito        - Configura un VirtualHost e un database MySQL per un dominio"
  echo -e "3) Disinstalla un sito     - Rimuove un VirtualHost e un database MySQL"
  echo -e "4) Imposta permessi WP     - Configura i permessi di sicurezza per un sito WordPress"
  echo -e "5) Genera certificato SSL  - Genera un certificato SSL per un sito"
  echo -e "6) Lista siti              - Mostra l'elenco dei siti presenti"
  echo -e "7) Esci                    - Esci dallo script"
  echo -e "========================================================================================"
  echo -e "${RESET}"
}

# Funzione per installare il server LAMP
installa_lamp() {
  # Aggiorna il sistema
  apt update || { echo -e "${RED}Errore nell'aggiornamento dei pacchetti${RESET}"; exit 1; }

  # ==================================================
  # APACHE
  # ==================================================
  # Verifica se Apache è già installato, se non lo è, installalo
  if ! [ -x "$(command -v apache2)" ]; then
    apt install apache2 -y || { echo -e "${RED}Errore nell'installazione di Apache${RESET}"; exit 1; }
    # Abilita Apache nel firewall
    ufw allow in "Apache"
    # Abilita mod_rewrite
    a2enmod rewrite || { echo -e "${RED}Errore nell'abilitazione di mod_rewrite${RESET}"; exit 1; }
    systemctl restart apache2
    echo -e "${GREEN}Apache installato e configurato.${RESET}"
  else
    echo -e "${YELLOW}Apache è già installato.${RESET}"
  fi

  # ==================================================
  # MYSQL
  # ==================================================
  # Verifica se MySQL è già installato, se non lo è, installalo
  if ! [ -x "$(command -v mysql)" ]; then
    apt install mysql-server -y || { echo -e "${RED}Errore nell'installazione di MySQL${RESET}"; exit 1; }
    # Richiedi all'utente di inserire la nuova password
    read -s -p "Inserisci la password per l'utente root di MySQL: " new_password
    echo
    # Configura MySQL
    mysql -u root -p -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$new_password';" || { echo -e "${RED}Errore nella configurazione di MySQL${RESET}"; exit 1; }
    mysql_secure_installation <<EOF
$new_password
n
y
y
y
y
EOF
    echo -e "${GREEN}MySQL installato e configurato.${RESET}"
  else
    echo -e "${YELLOW}MySQL è già installato.${RESET}"
  fi

  # ==================================================
  # PHP
  # ==================================================
  # Verifica se PHP è già installato
  if [ -x "$(command -v php)" ]; then
    php_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    echo -e "${YELLOW}PHP versione $php_version già installata.${RESET}"
  else
    apt install php libapache2-mod-php php-mysql -y || { echo -e "${RED}Errore nell'installazione di PHP"; exit 1; }
    php_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    echo -e "${GREEN}PHP versione $php_version installata.${RESET}"
  fi

  # Installa i pacchetti aggiuntivi in base alla versione di PHP
  apt install \
  php${php_version}-curl \
  php${php_version}-xml \
  php${php_version}-imagick \
  php${php_version}-mbstring \
  php${php_version}-zip \
  php${php_version}-intl \
  php-fdomdocument \
  php${php_version}-gd \
  php${php_version}-intl \
  -y || {
    echo -e "${RED}Errore nell'installazione dei pacchetti aggiuntivi di PHP${RESET}"
    exit 1
  }

  # ==================================================
  # CERTBOT
  # ==================================================
  # Verifica se Certbot è già installato
  if ! [ -x "$(command -v certbot)" ]; then
    apt install certbot python3-certbot-apache -y || { echo -e "${RED}Errore nell'installazione di Certbot${RESET}"; exit 1; }
    echo -e "${GREEN}Certbot per Apache installato.${RESET}"
  else
    echo -e "${YELLOW}Certbot è già installato.${RESET}"
  fi

  echo -e "${GREEN}Installazione del server LAMP e Certbot completata.${RESET}"
}

# Funzione per installare un sito Wordpress
installa_sito() {
  # Verifica se il server LAMP è installato
  if ! [ -x "$(command -v apache2)" ] || ! [ -x "$(command -v mysql)" ] || ! [ -x "$(command -v php)" ]; then
    echo -e "${YELLOW}Il server LAMP non è installato. Installalo prima di procedere.${RESET}"
    exit 1
  fi

  echo -e "Inserisci il nome del dominio (esempio.com oppure sub.esempio.com):"
  read -p "Dominio: " domain
  if [ -f /etc/apache2/sites-available/$domain.conf ]; then
    echo -e "${YELLOW}Il dominio esiste già!${RESET}"
    exit
  fi

  echo -e "Inserisci il nome del database (esempio_db):"
  read -p "Nome del database: " database
  if [ -d /var/lib/mysql/$database ]; then
    echo -e "${YELLOW}Il database esiste già!${RESET}"
    exit
  fi

  # Chiedi all'utente di inserire le credenziali del database
  echo -e "Inserisci l'username dell'utente del database:"
  read -p "Nome utente:" db_user

  # Chiedi all'utente di inserire la password del database
  echo "Inserisci la password per l'utente del database:"
  read -s -p "Password:" db_password
  echo

  # Chiedi all'utente di inserire la password ROOT per MySQL
  echo "Inserisci la password ROOT per MySQL:"
  read -s -p "Root password:" db_root_password
  echo

  # Chiedi all'utente se vuole creare un sito WordPress
  read -p "Vuoi creare un sito WordPress? (y/n): " -n 1 -r wordpress_choice
  echo

  # Configura la cartella di destinazione e il VirtualHost
  if [[ "$wordpress_choice" == "y" || "$wordpress_choice" == "Y" ]]; then
    doc_root="/var/www/$domain/wordpress"
    wordpress_download=true
  else
    doc_root="/var/www/$domain"
    wordpress_download=false
  fi

# Creazione del file di configurazione di Apache
tee /etc/apache2/sites-available/$domain.conf <<EOF
<VirtualHost *:80>
    ServerName $domain
    ServerAlias www.$domain
    DocumentRoot $doc_root
    CustomLog /var/log/apache2/$domain-access.log combined
    ErrorLog /var/log/apache2/$domain-error.log
    <Directory $doc_root>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

  # Abilita il nuovo sito
  a2ensite $domain.conf

  # Creazione della cartella DocumentRoot
  mkdir -p /var/www/$domain

  # Riavvia Apache per applicare le modifiche
  service apache2 restart

  # Scarica e decomprimi WordPress solo se richiesto
  if $wordpress_download; then
    wget -P /var/www/$domain https://wordpress.org/latest.zip
    if ! dpkg -l | grep -q unzip; then
      sudo apt-get install -y unzip || { echo -e "${RED}Errore nell'installazione di unzip"; exit 1; }
    fi
    unzip /var/www/$domain/latest.zip -d /var/www/$domain || { echo -e "${RED}Errore nell'estrazione di WordPress${RESET}"; exit 1; }
    rm /var/www/$domain/latest.zip
    chown -R www-data:www-data /var/www/$domain/wordpress
  fi

  # Imposta i permessi della cartella DocumentRoot
  chown -R www-data:www-data /var/www/$domain
  chmod -R g+rw /var/www/$domain

  # Creazione del database MariaDB
  mysql -uroot -p"$db_root_password" -e "CREATE DATABASE $database;" || { echo -e "${RED}Errore nella creazione del database${RESET}"; exit 1; }
  mysql -uroot -p"$db_root_password" -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_password';" || { echo -e "${RED}Errore nella creazione dell'utente MySQL${RESET}"; exit 1; }
  mysql -uroot -p"$db_root_password" -e "GRANT ALL PRIVILEGES ON $database.* TO '$db_user'@'localhost';" || { echo -e "${RED}Errore nell'assegnazione dei permessi all'utente MySQL${RESET}"; exit 1; }
  mysql -uroot -p"$db_root_password" -e "FLUSH PRIVILEGES;" || { echo -e "${RED}Errore nel flush dei permessi${RESET}"; exit 1; }

  # Aggiungi il dominio a /etc/hosts
  echo -e "127.0.0.1 $domain" | tee -a /etc/hosts

  # Riavvia cloudflared se installato
  if [ -f /usr/local/bin/cloudflared ]; then
    cloudflared service restart
  fi

  # Riavvia Apache per applicare le modifiche
  service apache2 restart || { echo -e "${RED}Errore nel riavvio di Apache${RESET}"; exit 1; }

  if $wordpress_download; then
    echo -e "${GREEN}WordPress è stato scaricato e configurato nella cartella $doc_root${RESET}"
  else
    echo -e "${GREEN}Il sito è stato creato nella cartella $doc_root${RESET}"
  fi

}

disinstalla_sito() {
  # Elenca tutti i file di configurazione dei siti disponibili
  echo -e "Ecco l'elenco dei siti disponibili:\n"
  sites=($(ls /etc/apache2/sites-available/*.conf | xargs -n 1 basename | sed 's/\.conf$//'))
  
  if [ ${#sites[@]} -eq 0 ]; then
    echo -e "${RED}Non ci sono siti disponibili da rimuovere.${RESET}"
    exit 1
  fi

  # Mostra i siti con numerazione
  for i in "${!sites[@]}"; do
    echo "$((i + 1)). ${sites[i]}"
  done

  # Chiede all'utente di scegliere un sito
  echo -e "\nInserisci il numero del sito da rimuovere:"
  read -p "Numero: " site_number

  # Verifica se l'input è valido
  if ! [[ "$site_number" =~ ^[0-9]+$ ]] || [ "$site_number" -lt 1 ] || [ "$site_number" -gt "${#sites[@]}" ]; then
    echo -e "${RED}Scelta non valida. Uscita.${RESET}"
    exit 1
  fi

  # Ottiene il nome del dominio scelto
  domain="${sites[$((site_number - 1))]}"
  conf_file="/etc/apache2/sites-available/$domain.conf"

  echo -e "Hai selezionato il dominio: $domain"

  # Estrai il DocumentRoot dal file di configurazione di Apache
  document_root=$(grep -i "DocumentRoot" "$conf_file" | awk '{print $2}')
  # Estrai i file di log dal file di configurazione di Apache
  access_log=$(grep -i "CustomLog" "$conf_file" | awk '{print $2}' | head -n 1)
  error_log=$(grep -i "ErrorLog" "$conf_file" | awk '{print $2}' | head -n 1)

  # Chiedi all'utente se vuole rimuovere il database
  read -p "Vuoi rimuovere il database associato a $domain? (y/n): " -n 1 -r remove_db
  echo

  # Rimuovi il database se richiesto
  if [[ "$remove_db" == "y" || "$remove_db" == "Y" ]]; then
    echo -e "Inserisci il nome del database da rimuovere:"
    read -p "Nome del database: " database
    mysql -uroot -p -e "DROP DATABASE $database;" || { echo -e "${RED}Errore nella rimozione del database${RESET}"; exit 1; }
    echo -e "${GREEN}Il database $database è stato rimosso.${RESET}"
  fi

  # Rimuovi il VirtualHost
  a2dissite "$domain.conf"
  rm "$conf_file"
  [ -f "/etc/apache2/sites-enabled/$domain.conf" ] && rm "/etc/apache2/sites-enabled/$domain.conf"

  # Verifica se esiste un file di configurazione SSL
  ssl_conf_file="/etc/apache2/sites-available/$domain-ssl.conf"
  if [ -f "$ssl_conf_file" ]; then
    rm "$ssl_conf_file"
    [ -f "/etc/apache2/sites-enabled/$domain-ssl.conf" ] && rm "/etc/apache2/sites-enabled/$domain-ssl.conf"
  fi

  # Rimuovi i file di log
  if [ -n "$access_log" ] && [ -f "$access_log" ]; then
    rm "$access_log"
    echo -e "${GREEN}Il file di log degli accessi è stato rimosso: $access_log${RESET}"
  fi
  if [ -n "$error_log" ] && [ -f "$error_log" ]; then
    rm "$error_log"
    echo -e "${GREEN}Il file di log degli errori è stato rimosso: $error_log${RESET}"
  fi

  # Rimuovi il dominio da /etc/hosts
  sed -i "/$domain/d" /etc/hosts

  # Rimuovi la cartella DocumentRoot
  if [ -n "$document_root" ] && [ -d "$document_root" ]; then
    rm -rf "$document_root"
    echo -e "${GREEN}La cartella DocumentRoot è stata rimossa: $document_root${RESET}"
  else
    echo -e "${YELLOW}La cartella DocumentRoot non è stata trovata o non esiste: $document_root${RESET}"
  fi

  # Riavvia Apache per applicare le modifiche
  service apache2 restart || { echo -e "${RED}Errore nel riavvio di Apache${RESET}"; exit 1; }

  echo -e "${GREEN}Il sito $domain è stato rimosso con successo.${RESET}"
}

permessi_wordpress() {
  echo -e "Inserisci il nome del dominio per cui vuoi settare i permessi (esempio.com oppure sub.esempio.com):"
  read -p "Dominio: " domain

  # Verifica se il dominio esiste, altrimenti esce
  if [ ! -d "/var/www/$domain" ]; then
    echo -e "${RED}Il dominio inserito non esiste${RESET}"
    exit
  fi

  WP_OWNER=www-data # <-- wordpress owner
  WP_GROUP=www-data # <-- wordpress group
  WP_ROOT=/var/www/$domain/wordpress # <-- wordpress root directory
  WS_GROUP=www-data # <-- webserver group

  # Reseta ai valori di default
  find ${WP_ROOT} -exec chown ${WP_OWNER}:${WP_GROUP} {} \;
  find ${WP_ROOT} -type d -exec chmod 755 {} \;
  find ${WP_ROOT} -type f -exec chmod 644 {} \;

  # Abilita WordPress a gestire .htaccess
  touch ${WP_ROOT}/.htaccess
  chgrp ${WS_GROUP} ${WP_ROOT}/.htaccess
  chmod 644 ${WP_ROOT}/.htaccess # Impostato a 644 per limitare i permessi

  # Abilita WordPress a gestire wp-content
  find ${WP_ROOT}/wp-content -exec chown -R ${WP_OWNER}:${WS_GROUP} {} \; # Modificato il gruppo a WS_GROUP per wp-content
  find ${WP_ROOT}/wp-content -type d -exec chmod 775 {} \;
  find ${WP_ROOT}/wp-content -type f -exec chmod 664 {} \;


  # Abilita WordPress a gestire wp-config.php (ma previene l'accesso di chiunque altro), se il file esiste
  if [ -f ${WP_ROOT}/wp-config.php ]; then
    chown ${WP_OWNER}:${WS_GROUP} ${WP_ROOT}/wp-config.php
    chmod 640 ${WP_ROOT}/wp-config.php # Impostato a 640 per limitare i permessi
    MSG=""
  else
    MSG="Ricordati reimpostare i permessi dopo aver completato la configurazione di WordPress!!!"
  fi

  ### ESITO ###
  # Se non ci sono errori, mostra un messaggio di successo
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}I permessi sono stati impostati correttamente. $MSG${RESET}"
  else
    echo -e "${RED}Si è verificato un errore durante l'impostazione dei permessi${RESET}"
  fi
}

genera_certificato() {
  # Verifica se Certbot è installato, altrimenti esci
  if ! [ -x "$(command -v certbot)" ]; then
    echo -e "${RED}Certbot non è installato. Installalo prima di procedere.${RESET}"
    exit 1
  fi

  # Mostar elenco dei domini e chiedere all'utente di sceglierne uno per cui generare il certificato
  echo -e "Ecco l'elenco dei siti disponibili:\n"
  sites=($(ls /etc/apache2/sites-available/*.conf | xargs -n 1 basename | sed 's/\.conf$//'))

  if [ ${#sites[@]} -eq 0 ]; then
    echo -e "${RED}Non ci sono siti disponibili per generare un certificato.${RESET}"
    exit 1
  fi

  # Mostra i siti con numerazione
  for i in "${!sites[@]}"; do
    echo "$((i + 1)). ${sites[i]}"
  done

  # Chiedi all'utente di scegliere un sito
  echo -e "\nInserisci il numero del sito per cui generare il certificato:"
  read -p "Numero: " site_number

  # Verifica se l'input è valido
  if ! [[ "$site_number" =~ ^[0-9]+$ ]] || [ "$site_number" -lt 1 ] || [ "$site_number" -gt "${#sites[@]}" ]; then
    echo -e "${RED}Scelta non valida. Uscita.${RESET}"
    exit 1
  fi

  # Ottiene il nome del dominio scelto
  domain="${sites[$((site_number - 1))]}"
  echo -e "Hai selezionato il dominio: $domain"

  # Genera il certificato SSL
  certbot --apache -d $domain

  # Riavvia Apache per applicare le modifiche
  service apache2 restart || { echo -e "${RED}Errore nel riavvio di Apache${RESET}"; exit 1; }

  echo -e "${GREEN}Il certificato SSL per $domain è stato generato con successo.${RESET}"
}

# Funzione per ottenere la lista dei siti presenti
lista_siti() {
  # Verifica che la directory dei file di configurazione esista
  if [ -d /etc/apache2/sites-available ]; then
    echo -e "Elenco dei siti presenti:"
    # Elenca i file nella directory, rimuovi l'estensione ".conf" per ottenere solo i nomi dei domini
    for site in /etc/apache2/sites-available/*.conf; do
      # Estrai solo il nome del sito, rimuovendo il percorso e l'estensione
      basename "$site" .conf
    done
  else
    echo -e "${RED}La directory /etc/apache2/sites-available non esiste.${RESET}"
  fi
}

# Funzione per eseguire le azioni
esegui_azione() {
  case $1 in
    1)
      installa_lamp
      ;;
    2)
      installa_sito
      ;;
    3)
      disinstalla_sito
      ;;
    4)
      permessi_wordpress
      ;;
    5)
      genera_certificato
      ;;
    6)
      lista_siti
      ;;
    7)
      echo -e "Uscita dal programma."
      exit 0
      ;;
    *)
      echo -e "Scelta non valida, riprova."
      ;;
  esac
}

# Loop principale
while true; do
  mostra_menu
  read -p "Seleziona un'opzione (1-6): " scelta
  esegui_azione $scelta
done
