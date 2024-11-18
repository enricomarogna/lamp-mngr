#!/bin/bash

# Created by: Enrico Marogna - https://enricomarogna.com
# Version 1.9.0
# Tested on Ubuntu 22.04 LTS
# ---------------------------------------------------------
# This script automates the installation and configuration of a LAMP server (Linux, Apache, MySQL, PHP) on an Ubuntu system.
# It allows the creation of Apache VirtualHosts, management of a MySQL database for a website, and includes the option to
# configure a WordPress site with appropriate security permissions. It checks and sets necessary configurations,
# such as file permissions and the use of Apache modules. It also includes basic MySQL security management.
# It is recommended to run the script with root privileges to ensure all operations are executed correctly:
# "sudo chown root lamp-mngr.sh && sudo chmod 700 lamp-mngr.sh"
# To run the script, type "sudo ./lamp-mngr.sh"
# ---------------------------------------------------------

# COLORS
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
PURPLE='\033[35m'
RESET='\033[0m'

echo ""
echo ""
echo ""
echo -e "${GREEN}"
echo "   ██▓    ▄▄▄       ███▄ ▄███▓ ██▓███   ███▄ ▄███▓ ███▄    █   ▄████  ██▀███  "
echo "  ▓██▒   ▒████▄    ▓██▒▀█▀ ██▒▓██░  ██▒▓██▒▀█▀ ██▒ ██ ▀█   █  ██▒ ▀█▒▓██ ▒ ██▒"
echo "  ▒██░   ▒██  ▀█▄  ▓██    ▓██░▓██░ ██▓▒▓██    ▓██░▓██  ▀█ ██▒▒██░▄▄▄░▓██ ░▄█ ▒"
echo "  ▒██░   ░██▄▄▄▄██ ▒██    ▒██ ▒██▄█▓▒ ▒▒██    ▒██ ▓██▒  ▐▌██▒░▓█  ██▓▒██▀▀█▄  "
echo "  ░██████▒▓█   ▓██▒▒██▒   ░██▒▒██▒ ░  ░▒██▒   ░██▒▒██░   ▓██░░▒▓███▀▒░██▓ ▒██▒"
echo "  ░ ▒░▓  ░▒▒   ▓▒█░░ ▒░   ░  ░▒▓▒░ ░  ░░ ▒░   ░  ░░ ▒░   ▒ ▒  ░▒   ▒ ░ ▒▓ ░▒▓░"
echo "  ░ ░ ▒  ░ ▒   ▒▒ ░░  ░      ░░▒ ░     ░  ░      ░░ ░░   ░ ▒░  ░   ░   ░▒ ░ ▒░"
echo "    ░ ░    ░   ▒   ░      ░   ░░       ░      ░      ░   ░ ░ ░ ░   ░   ░░   ░ "
echo "      ░  ░     ░  ░       ░                   ░            ░       ░    ░     "
echo -e "${RESET}"
echo "Created by: Enrico Marogna - v1.9.0"
echo ""
echo ""

# Funzione per mostrare il menu
show_menu() {
  ## Se lo script non è lanciato come root, esci
  if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}You must run the script as root${RESET}"
    exit 1
  fi

  # se il file stesso non non è di proprietà di root e non ha i permessi 700, esci
  if [ "$(stat -c %U $0)" != "root" ] || [ "$(stat -c %a $0)" != "700" ]; then
    path_script=$(realpath $0)
    echo -e "${RED}The script must be owned by root and have 700 permissions to be executed securely:${RESET}"
    echo -e "Run: ${BLUE}sudo chown root:root $path_script && sudo chmod 700 $path_script${RESET}"
    exit 1
  fi

  echo -e "${PURPLE}"
  echo -e "==========================================================================================================================="
  echo -e "                                             LAMP Server Manager                                                           "
  echo -e "==========================================================================================================================="
  echo -e "1) Install LAMP Server       - Installs Apache, MySQL, PHP, and Certbot"
  echo -e "2) Create a Site             - Creates an Apache VirtualHost and a MySQL database for a site (with an option for WordPress)"
  echo -e "3) Uninstall Site            - Removes a specific site, including files, database, Apache VirtualHost, and log files"
  echo -e "4) Set WP Permissions        - Configures security permissions for a WordPress site"
  echo -e "5) Generate SSL Certificate  - Installs and configures an SSL certificate for a domain"
  echo -e "6) List Installed Sites      - Displays a list of installed sites"
  echo -e "7) Exit                      - Exits the script"
  echo -e "==========================================================================================================================="
  echo -e "${RESET}"
}

# ==================================================
# Function to install the LAMP server
# ==================================================
install_lamp() {
  # Aggiorna il sistema
  apt update || { echo -e "${RED}Error updating packages${RESET}"; exit 1; }

  # APACHE
  # Verifica se Apache è già installato, se non lo è, installalo
  if ! [ -x "$(command -v apache2)" ]; then
    apt install apache2 -y || { echo -e "${RED}Error installing Apache${RESET}"; exit 1; }
    # Abilita Apache nel firewall
    ufw allow in "Apache"
    # Abilita mod_rewrite
    a2enmod rewrite || { echo -e "${RED}Error enabling mod_rewrite${RESET}"; exit 1; }
    systemctl restart apache2
    echo -e "${GREEN}Apache installed and configured.${RESET}"
  else
    echo -e "${YELLOW}Apache is already installed.${RESET}"
  fi

  # MYSQL
  # Check if MySQL is already installed, if not, install it
  if ! [ -x "$(command -v mysql)" ]; then
    apt install mysql-server -y || { echo -e "${RED}Error installing MySQL${RESET}"; exit 1; }
    # Richiedi all'utente di inserire la nuova password
    read -s -p "Enter the password for the MySQL root user: " new_password
    echo
    # Configura MySQL
    mysql -u root -p -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$new_password';" || { echo -e "${RED}Error configuring MySQL${RESET}"; exit 1; }
    mysql_secure_installation <<EOF
$new_password
n
y
y
y
y
EOF
    echo -e "${GREEN}MySQL installed and configured.${RESET}"
  else
    echo -e "${YELLOW}MySQL is already installed.${RESET}"
  fi

  # PHP
  # Check if PHP is already installed
  if [ -x "$(command -v php)" ]; then
    php_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    echo -e "${YELLOW}PHP version $php_version already installed.${RESET}"
  else
    apt install php libapache2-mod-php php-mysql -y || { echo -e "${RED}Error installing PHP."; exit 1; }
    php_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    echo -e "${GREEN}PHP version $php_version installed.${RESET}"
  fi

  # Install additional packages based on the PHP version
  apt install \
  php${php_version}-curl \
  php${php_version}-xml \
  php${php_version}-imagick \
  php${php_version}-mbstring \
  php${php_version}-zip \
  php${php_version}-intl \
  php${php_version}-gd \
  php-fdomdocument \
  -y || {
    echo -e "${RED}Error installing additional PHP packages${RESET}"
    exit 1
  }

  # CERTBOT
  # Check if Certbot is already installed
  if ! [ -x "$(command -v certbot)" ]; then
    apt install certbot python3-certbot-apache -y || { echo -e "${RED}Error installing Certbot${RESET}"; exit 1; }
    echo -e "${GREEN}Certbot for Apache installed.${RESET}"
  else
    echo -e "${YELLOW}Certbot is already installed.${RESET}"
  fi

  echo -e "${GREEN}LAMP server and Certbot installation completed.${RESET}"
}

# ==================================================
# Function to install a site
# ==================================================
install_site() {
  # Verifica se il server LAMP è installato
  if ! [ -x "$(command -v apache2)" ] || ! [ -x "$(command -v mysql)" ] || ! [ -x "$(command -v php)" ]; then
    echo -e "${YELLOW}The LAMP server is not installed. Install it first before proceeding.${RESET}"
    exit 1
  fi

  echo -e "Enter the domain name (example.com or sub.example.com):"
  read -p "Domain: " domain
  if [ -f /etc/apache2/sites-available/$domain.conf ]; then
    echo -e "${YELLOW}The domain already exists!${RESET}"
    exit
  fi

  echo -e "Enter the database name (example_db):"
  read -p "Database name: " database
  if [ -d /var/lib/mysql/$database ]; then
    echo -e "${YELLOW}The database already exists!${RESET}"
    exit
  fi

  # Ask the user to enter the database credentials
  echo -e "Enter the database user username:"
  read -p "Database username:" db_user

  # Ask the user to enter the database password
  echo "Enter the password for the database user:"
  read -s -p "Password:" db_password
  echo

  # Ask the user to enter the ROOT password for MySQL
  echo "Enter the ROOT password for MySQL:"
  read -s -p "Root password:" db_root_password
  echo

  # Chiedi all'utente se vuole creare un sito WordPress
  read -p "Do you want to create a WordPress site? (y/n): " -n 1 -r wordpress_choice
  echo

  # Set the WordPress download flag based on the user's choice
  if [[ "$wordpress_choice" == "y" || "$wordpress_choice" == "Y" ]]; then
    wordpress_download=true
  else
    wordpress_download=false
  fi

  # Set the DocumentRoot
  doc_root="/var/www/$domain"

  # Verify if the database login credentials are correct, otherwise exit.
  mysql -uroot -p"$db_root_password" -e "exit" || { echo -e "${RED}Incorrect database login credentials${RESET}"; exit 1; }

# Creating Apache configuration file
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

  # Enable the new site
  a2ensite $domain.conf

  # Creating the DocumentRoot directory
  mkdir -p /var/www/$domain

  # Restart Apache to apply the changes
  service apache2 restart

  # Download and extract WordPress only if requested
  if $wordpress_download; then
    wget -P /var/www/$domain https://wordpress.org/latest.zip
    if ! dpkg -l | grep -q unzip; then
      sudo apt-get install -y unzip || { echo -e "${RED}Error installing unzip"; exit 1; }
    fi
    unzip /var/www/$domain/latest.zip -d /var/www/$domain || { echo -e "${RED}Error extracting WordPress${RESET}"; exit 1; }
    rm /var/www/$domain/latest.zip
    chown -R www-data:www-data /var/www/$domain
  fi

  # Set permissions for the DocumentRoot directory
  chown -R www-data:www-data /var/www/$domain
  chmod -R g+rw /var/www/$domain

  # Creazione del database MariaDB
  mysql -uroot -p"$db_root_password" -e "CREATE DATABASE $database;" || { echo -e "${RED}Error in creating the database${RESET}"; exit 1; }
  mysql -uroot -p"$db_root_password" -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_password';" || { echo -e "${RED}Error creating MySQL user${RESET}"; exit 1; }
  mysql -uroot -p"$db_root_password" -e "GRANT ALL PRIVILEGES ON $database.* TO '$db_user'@'localhost';" || { echo -e "${RED}Error assigning permissions to MySQL user${RESET}"; exit 1; }
  mysql -uroot -p"$db_root_password" -e "FLUSH PRIVILEGES;" || { echo -e "${RED}Error flushing permissions${RESET}"; exit 1; }

  # Add the domain to /etc/hosts
  echo -e "127.0.0.1 $domain" | tee -a /etc/hosts

  # Restart cloudflared if installed
  if [ -f /usr/local/bin/cloudflared ]; then
    cloudflared service restart
  fi

  # Restart Apache to apply changes
  service apache2 restart || { echo -e "${RED}Error restarting Apache${RESET}"; exit 1; }

  if $wordpress_download; then
    echo -e "${GREEN}WordPress è stato scaricato e configurato nella cartella $doc_root${RESET}"
  else
    echo -e "${GREEN}The website has been created in the $doc_root folder.${RESET}"
  fi

}

# ==================================================
# Funzione per disinstallare un sito
# ==================================================
uninstall_site() {
  # Elenca tutti i file di configurazione dei siti disponibili
  echo ""
  echo -e "Ecco l'elenco dei siti disinstallabili:\n"

  # Raccoglie solo i siti base, escludendo le configurazioni SSL
  sites=($(ls /etc/apache2/sites-available/*.conf | xargs -n 1 basename | sed 's/\.conf$//' | sed 's/-le-ssl$//' | sort -u))

  # Se non ci sono siti disponibili, esci
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

  # Verifica se esiste un file di configurazione SSL. Se esiste, rimuovi il certificato SSL associato e disabilita il VirtualHost SSL
  ssl_conf_file="/etc/apache2/sites-available/$domain-le-ssl.conf"
  if [ -f "$ssl_conf_file" ]; then
    a2dissite "$domain-ssl.conf"
    systemctl reload apache2
    certbot delete --cert-name "$domain" || echo -e "${RED}Errore nella rimozione del certificato${RESET}"
    rm -f "$ssl_conf_file" "/etc/apache2/sites-enabled/$domain-le-ssl.conf"
    rm -rf "/etc/letsencrypt/live/$domain" "/etc/letsencrypt/archive/$domain" "/etc/letsencrypt/renewal/$domain.conf"
    echo -e "${GREEN}Certificato SSL per $domain rimosso.${RESET}"
  else
    echo -e "${YELLOW}Nessun certificato SSL trovato per $domain.${RESET}"
  fi


  # Rimuovi il database se richiesto
  # Chiedi all'utente se vuole rimuovere il database associato al dominio
  # Se l'utente conferma, chiedi il nome del database e rimuovilo
  # Se l'utente non conferma, salta la rimozione del database
  read -p "Vuoi rimuovere il database associato a $domain? (y/n): " -n 1 -r remove_db
  echo ""
  # Chiedi conferma, salavndo la risposta in romove_db_check
  echo -e "${YELLOW}ATTENZIONE: Questa operazione rimuoverà definitivamente il database e tutti i dati associati.${RESET}"
  read -p "Procedere con la rimozione del database? (y/n): " -n 1 -r remove_db_check
  echo ""
  if [[ "$remove_db" =~ ^[Yy]$ ]] && [[ "$remove_db_check" =~ ^[Yy]$ ]]; then
    echo -e "Inserisci il nome del database da rimuovere:"
    read -p "Nome del database: " database
    if [[ -n "$database" ]]; then
      mysql -uroot -p -e "DROP DATABASE $database;" || { echo -e "${RED}Errore nella rimozione del database${RESET}"; }
      echo -e "${GREEN}Il database $database è stato rimosso.${RESET}"
    else
      echo -e "${RED}Nome del database non valido. Operazione annullata.${RESET}"
    fi
  fi

  # Rimuovi il VirtualHost
  a2dissite "$domain.conf"
  rm "$conf_file"
  [ -f "/etc/apache2/sites-enabled/$domain.conf" ] && rm "/etc/apache2/sites-enabled/$domain.conf"

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

# ==================================================
# Funzione per impostare i permessi di WordPress
# ==================================================
wordpress_permissions() {
  # Elenca tutti i file di configurazione dei siti disponibili
  echo -e "Ecco l'elenco dei siti disponibili:\n"

  # Raccoglie solo i siti base, escludendo le configurazioni SSL
  sites=($(find /etc/apache2/sites-available -maxdepth 1 -type f -name "*.conf" ! -name "*-ssl.conf" -exec basename {} .conf \; | sort -u))

  if [ ${#sites[@]} -eq 0 ]; then
    echo -e "${RED}Non ci sono siti disponibili per cui modificare i permessi.${RESET}"
    exit 1
  fi

  # Mostra i siti con numerazione
  for i in "${!sites[@]}"; do
    echo "$((i + 1)). ${sites[i]}"
  done

  # Chiede all'utente di scegliere un sito
  echo -e "\nInserisci il numero del sito per cui modificare i permessi:"
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

  WP_OWNER=www-data # <-- wordpress owner
  WP_GROUP=www-data # <-- wordpress group
  WP_ROOT=$document_root # <-- wordpress root directory
  WS_GROUP=www-data # <-- webserver group

  # Resetta ai valori di default
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

# ==================================================
# Funzione per generare un certificato SSL
# ==================================================
generate_certificate() {
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
}

# ==================================================
# Funzione per ottenere la lista dei siti presenti
# ==================================================
sites_list() {
  # Rileva i file di configurazione di Apache
  config_files=$(grep -Rl "DocumentRoot" /etc/apache2/sites-available/)

  if [ -z "$config_files" ]; then
    echo -e "Non sono stati trovati file di configurazione con DocumentRoot."
    return 1
  fi

  # Stampa l'intestazione della tabella con larghezza fissa per le colonne
  echo ""
  printf "%-50s | %-3s | %-70s | %-10s\n" "Dominio" "SSL" "DocumentRoot" "WordPress"
  printf "%-50s-+-%-3s-+-%-70s-+-%-10s\n" "$(printf '%.0s-' {1..50})" "---" "$(printf '%.0s-' {1..70})" "----------"

  # Lista dei domini già processati
  processed_domains=()

  # Itera attraverso ogni file di configurazione
  for file in $config_files; do
    # Estrai il dominio (ServerName) e il DocumentRoot
    domain=$(grep -i "ServerName" "$file" | awk '{print $2}')
    doc_root=$(grep -i "DocumentRoot" "$file" | awk '{print $2}')

    # Se il dominio o il DocumentRoot non sono stati trovati, salta al prossimo
    if [ -z "$domain" ] || [ -z "$doc_root" ]; then
      continue
    fi

    # Se il dominio è già stato processato, salta il file (per evitare duplicazioni)
    if [[ " ${processed_domains[@]} " =~ " ${domain} " ]]; then
      continue
    fi

    # Aggiungi il dominio alla lista dei domini processati
    processed_domains+=("$domain")

    # Troncamento del dominio e DocumentRoot per evitare righe troppo lunghe
    domain=$(echo $domain | cut -c1-50)  # Truncare il dominio a 50 caratteri
    doc_root=$(echo $doc_root | cut -c1-70)  # Truncare DocumentRoot a 70 caratteri

    # Controlla se il sito ha una regola di reindirizzamento verso HTTPS
    ssl_enabled="No"
    if grep -qi "RewriteRule" "$file" && grep -qi "https" "$file"; then
      ssl_enabled="Sì "
    fi

    # Controlla se è un sito WordPress (verifica se esiste il file wp-config.php)
    is_wordpress="No"
    if [ -f "${doc_root}/wp-config.php" ] && [ -d "${doc_root}/wp-content" ] && [ -d "${doc_root}/wp-includes" ]; then
      is_wordpress="Sì"
    fi

    # Stampa i dati nella tabella, forzando la lunghezza fissa per la colonna "SSL"
    printf "%-50s | %-3s | %-70s | %-10s\n" "$domain" "$ssl_enabled" "$doc_root" "$is_wordpress"
  done
}

# ==================================================
# Funzione per eseguire le azioni
# ==================================================
execute_action() {
  case $1 in
    1)
      install_lamp
      ;;
    2)
      install_site
      ;;
    3)
      uninstall_site
      ;;
    4)
      wordpress_permissions
      ;;
    5)
      generate_certificate
      ;;
    6)
      sites_list
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

# ==================================================
# Loop principale
# ==================================================
while true; do
  show_menu
  read -p "Select an option (1-7): " option_choice
  execute_action $option_choice
done
