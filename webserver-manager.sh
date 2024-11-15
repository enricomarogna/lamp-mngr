#!/bin/bash

# Creato da: Enrico Marogna - https://enricomarogna.com
# Versione 1.4
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

# Funzione per mostrare il menu
mostra_menu() {
  ## Se lo script non è lanciato come root, esci
  if [ "$EUID" -ne 0 ]; then
    echo "Devi eseguire lo script come root"
    exit 1
  fi

  # se il file stesso non non è di proprietà di root e non ha i permessi 700, esci
  if [ "$(stat -c %U $0)" != "root" ] || [ "$(stat -c %a $0)" != "700" ]; then
    path_script=$(realpath $0)
    echo "Lo script deve essere di proprietà di root e avere i permessi 700 per essere eseguito in sicurezza:"
    echo "Esegui: sudo chown root:root $path_script && sudo chmod 700 $path_script"
    exit 1
  fi

  echo "============================"
  echo "         MENU              "
  echo "============================"
  echo "1) Installa Server LAMP    - Installa Apache, MySQL, PHP e Certbot"
  echo "2) Crea un sito            - Configura un VirtualHost e un database MySQL per un dominio"
  echo "3) Imposta permessi WP     - Configura i permessi di sicurezza per un sito WordPress"
  echo "4) Esci                    - Esci dallo script"
  echo "============================"

}

# Funzione per installare il server LAMP
installa_lamp() {
  # Aggiorna il sistema
  apt update || { echo "Errore nell'aggiornamento dei pacchetti"; exit 1; }

  # ==================================================
  # APACHE
  # ==================================================
  # Verifica se Apache è già installato, se non lo è, installalo
  if ! [ -x "$(command -v apache2)" ]; then
    apt install apache2 -y || { echo "Errore nell'installazione di Apache"; exit 1; }
    # Abilita Apache nel firewall
    ufw allow in "Apache"
    # Abilita mod_rewrite
    a2enmod rewrite || { echo "Errore nell'abilitazione di mod_rewrite"; exit 1; }
    systemctl restart apache2
    echo "Apache installato e configurato."
  else
    echo "Apache è già installato."
  fi

  # ==================================================
  # MYSQL
  # ==================================================
  # Verifica se MySQL è già installato, se non lo è, installalo
  if ! [ -x "$(command -v mysql)" ]; then
    apt install mysql-server -y || { echo "Errore nell'installazione di MySQL"; exit 1; }
    # Richiedi all'utente di inserire la nuova password
    read -s -p "Inserisci la password per l'utente root di MySQL: " new_password
    echo
    # Configura MySQL
    mysql -u root -p -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$new_password';" || { echo "Errore nella configurazione di MySQL"; exit 1; }
    mysql_secure_installation <<EOF
$new_password
n
y
y
y
y
EOF
    echo "MySQL installato e configurato."
  else
    echo "MySQL è già installato."
  fi

  # ==================================================
  # PHP
  # ==================================================
  # Verifica se PHP è già installato
  if [ -x "$(command -v php)" ]; then
    php_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    echo "PHP versione $php_version già installata."
  else
    apt install php libapache2-mod-php php-mysql -y || { echo "Errore nell'installazione di PHP"; exit 1; }
    php_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    echo "PHP versione $php_version installata."
  fi

  # Installa i pacchetti aggiuntivi in base alla versione di PHP
  if [[ $php_version == "8.1" ]]; then
    apt install php8.1-curl php8.1-xml php8.1-imagick php8.1-mbstring php8.1-zip php8.1-intl php-fdomdocument php8.1-gd php8.1-intl -y || { echo "Errore nell'installazione dei pacchetti aggiuntivi di PHP"; exit 1; }
  elif [[ $php_version == "8.0" ]]; then
    apt install php8.0-curl php8.0-xml php8.0-imagick php8.0-mbstring php8.0-zip php8.0-intl php-fdomdocument php8.0-gd php8.0-intl -y || { echo "Errore nell'installazione dei pacchetti aggiuntivi di PHP"; exit 1; }
  elif [[ $php_version == "7.4" ]]; then
    apt install php7.4-curl php7.4-xml php7.4-imagick php7.4-mbstring php7.4-zip php7.4-intl php-fdomdocument php7.4-gd php7.4-intl -y || { echo "Errore nell'installazione dei pacchetti aggiuntivi di PHP"; exit 1; }
  else
    echo "Versione di PHP non supportata. Installa manualmente i pacchetti aggiuntivi corrispondenti."
  fi

  # ==================================================
  # CERTBOT
  # ==================================================
  # Verifica se Certbot è già installato
  if ! [ -x "$(command -v certbot)" ]; then
    apt install certbot python3-certbot-apache -y || { echo "Errore nell'installazione di Certbot"; exit 1; }
    echo "Certbot per Apache installato."
  else
    echo "Certbot è già installato."
  fi

  echo "Installazione del server LAMP e Certbot completata."
}

# Funzione per installare un sito Wordpress
installa_sito() {
  # Verifica se il server LAMP è installato
  if ! [ -x "$(command -v apache2)" ] || ! [ -x "$(command -v mysql)" ] || ! [ -x "$(command -v php)" ]; then
    echo "Il server LAMP non è installato. Installalo prima di procedere."
    exit 1
  fi

  echo "Inserisci il nome del dominio (esempio.com oppure sub.esempio.com):"
  read -p "Dominio: " domain
  if [ -f /etc/apache2/sites-available/$domain.conf ]; then
    echo "Il dominio esiste già!"
    exit
  fi

  echo "Inserisci il nome del database (esempio_db):"
  read -p "Nome del database: " database
  if [ -d /var/lib/mysql/$database ]; then
    echo "Il database esiste già!"
    exit
  fi

  echo "Inserisci le credenziali dell'utente del database (esempio_user):"
  read -p "Nome utente: " db_user

  echo "Inserisci la password per l'utente del database:"
  read -p "Password: " db_password

  echo "Inserisci la password ROOT per il database:"
  read -p "Password: " db_root_password

  # Chiedi se creare un sito WordPress
  echo "Vuoi creare un sito WordPress? (y/n)"
  read -p "Risposta: " wordpress_choice

  # Configura la cartella di destinazione e il VirtualHost
  if [[ "$wordpress_choice" == "y" || "$wordpress_choice" == "Y" ]]; then
    doc_root="/var/www/$domain/wordpress"
    wordpress_download=true
  else
    doc_root="/var/www/$domain"
    wordpress_download=false
  fi

# Creazione del file di configurazione di Apache
sudo tee /etc/apache2/sites-available/$domain.conf <<EOF
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
  sudo a2ensite $domain.conf

  # Creazione della cartella DocumentRoot
  sudo mkdir -p /var/www/$domain
  sudo chown -R www-data:www-data /var/www/$domain
  sudo chmod -R g+rw /var/www/$domain

  # Riavvia Apache per applicare le modifiche
  sudo service apache2 restart

  # Scarica e decomprimi WordPress solo se richiesto
  if $wordpress_download; then
    sudo wget -P /var/www/$domain https://wordpress.org/latest.zip
    sudo apt-get install -y unzip || { echo "Errore nell'installazione di unzip"; exit 1; }
    sudo unzip /var/www/$domain/latest.zip -d /var/www/$domain
    sudo rm /var/www/$domain/latest.zip
    sudo chown -R www-data:www-data /var/www/$domain/wordpress
  fi

# Creazione del database MariaDB
sudo mysql -uroot -p$db_root_password <<EOF
CREATE DATABASE $database;
CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_password';
GRANT ALL PRIVILEGES ON $database.* TO '$db_user'@'localhost';
FLUSH PRIVILEGES;
EOF

  # Aggiungi il dominio a /etc/hosts
  echo "127.0.0.1 $domain" | sudo tee -a /etc/hosts

  # Riavvia cloudflared se installato
  if [ -f /usr/local/bin/cloudflared ]; then
    sudo cloudflared service restart
  fi

  if $wordpress_download; then
    echo "WordPress è stato scaricato e configurato nella cartella $doc_root"
  else
    echo "Il sito è stato creato nella cartella $doc_root"
  fi

}

permessi_wordpress() {
  echo "Inserisci il nome del dominio per cui vuoi settare i permessi (esempio.com oppure sub.esempio.com):"
  read -p "Dominio: " domain

  # Verifica se il dominio esiste, altrimenti esce
  if [ ! -d "/var/www/$domain" ]; then
    echo "Il dominio inserito non esiste"
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
    echo "I permessi sono stati impostati correttamente. $MSG"
  else
    echo "Si è verificato un errore durante l'impostazione dei permessi"
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
      permessi_wordpress
      ;;
    4)
      echo "Uscita dal programma."
      exit 0
      ;;
    *)
      echo "Scelta non valida, riprova."
      ;;
  esac
}

# Loop principale
while true; do
  mostra_menu
  read -p "Seleziona un'opzione (1-4): " scelta
  esegui_azione $scelta
done
