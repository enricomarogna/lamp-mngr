#!/bin/bash

# Created by: Enrico Marogna - https://enricomarogna.com
Version="v1.11.0"
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
echo "Created by: Enrico Marogna - Version: $Version"
echo ""
echo ""

# ==================================================
# Function to show the main menu
# ==================================================
show_menu() {
  # If the script is not launched as root, exit
  if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}You must run the script as root${RESET}"
    exit 1
  fi

  # If the script itself is not owned by root and does not have 700 permissions, exit
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
  # Update the system
  apt update || { echo -e "${RED}Error updating packages${RESET}"; exit 1; }

  # APACHE
  # Check if Apache is already installed; if not, install it
  if ! [ -x "$(command -v apache2)" ]; then
    apt install apache2 -y || { echo -e "${RED}Error installing Apache${RESET}"; exit 1; }
    # Enable Apache in the firewall
    ufw allow in "Apache"
    # Enable mod_rewrite
    a2enmod rewrite || { echo -e "${RED}Error enabling mod_rewrite${RESET}"; exit 1; }
    systemctl restart apache2
    echo -e "${GREEN}Apache installed and configured.${RESET}"
  else
    echo -e "${YELLOW}Apache is already installed.${RESET}"
  fi

  # MYSQL
  # Check if MySQL is already installed; if not, install it
  if ! [ -x "$(command -v mysql)" ]; then
    apt install mysql-server -y || { echo -e "${RED}Error installing MySQL${RESET}"; exit 1; }
    # Ask the user to enter the new password
    read -s -p "Enter the password for the MySQL root user: " new_password
    echo
    # Configure MySQL
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
    apt install php libapache2-mod-php php-mysql -y || { echo -e "${RED}Error installing PHP.${RESET}"; exit 1; }
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
  # Check if the LAMP server is installed
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
  read -p "Database username: " db_user

  # Ask the user to enter the database password
  echo "Enter the password for the database user:"
  read -s -p "Password: " db_password
  echo

  # Ask the user to enter the ROOT password for MySQL
  echo "Enter the ROOT password for MySQL:"
  read -s -p "Root password: " db_root_password
  echo

  # Ask the user if they want to create a WordPress site
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

  # Verify if the database login credentials are correct, otherwise exit
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
      apt-get install -y unzip || { echo -e "${RED}Error installing unzip${RESET}"; exit 1; }
    fi
    unzip /var/www/$domain/latest.zip -d /var/www/$domain || { echo -e "${RED}Error extracting WordPress${RESET}"; exit 1; }
    rm /var/www/$domain/latest.zip

    # Move the WordPress files to the DocumentRoot
    mv /var/www/$domain/wordpress/* /var/www/$domain
    rm -rf /var/www/$domain/wordpress

    # -----------------------------------------------
    # Optional WP-CLI installation
    # -----------------------------------------------
    read -p "Do you want to install WP-CLI? (y/n): " -n 1 -r wpcli_choice
    echo

    if [[ "$wpcli_choice" == "y" || "$wpcli_choice" == "Y" ]]; then

      # Check if WP-CLI is already installed
      if [ -x "$(command -v wp)" ]; then
        existing_version=$(wp --info --allow-root 2>/dev/null | grep "WP-CLI version" | awk '{print $3}')
        echo -e "${YELLOW}WP-CLI is already installed (version $existing_version). Skipping installation.${RESET}"
      else
        echo -e "Downloading WP-CLI..."

        # Download the phar file
        wget -O /tmp/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
          || { echo -e "${RED}Error downloading WP-CLI${RESET}"; exit 1; }

        # Verify the integrity of the downloaded file
        php /tmp/wp-cli.phar --info --allow-root > /dev/null 2>&1 \
          || { echo -e "${RED}The WP-CLI file is corrupted or invalid${RESET}"; rm -f /tmp/wp-cli.phar; exit 1; }

        # Make it executable and move to a system-wide location
        chmod +x /tmp/wp-cli.phar
        mv /tmp/wp-cli.phar /usr/local/bin/wp \
          || { echo -e "${RED}Error moving WP-CLI to /usr/local/bin/wp${RESET}"; exit 1; }

        # Final check
        if wp --info --allow-root > /dev/null 2>&1; then
          wpcli_version=$(wp --info --allow-root | grep "WP-CLI version" | awk '{print $3}')
          echo -e "${GREEN}WP-CLI version $wpcli_version installed successfully in /usr/local/bin/wp${RESET}"
          echo ""
          echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════╗${RESET}"
          echo -e "${BLUE}║                       WP-CLI — Important Notes                      ║${RESET}"
          echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════════╣${RESET}"
          echo -e "${BLUE}║                                                                      ║${RESET}"
          echo -e "${BLUE}║  WP-CLI commands must always be run from the site's DocumentRoot.   ║${RESET}"
          echo -e "${BLUE}║                                                                      ║${RESET}"
          echo -e "${BLUE}║  • As root (requires --allow-root flag):                            ║${RESET}"
          echo -e "${BLUE}║    wp <command> --allow-root --path=$doc_root${RESET}"
          echo -e "${BLUE}║                                                                      ║${RESET}"
          echo -e "${BLUE}║  • As www-data (recommended for production):                        ║${RESET}"
          echo -e "${BLUE}║    sudo -u www-data wp <command> --path=$doc_root${RESET}"
          echo -e "${BLUE}║                                                                      ║${RESET}"
          echo -e "${BLUE}║  Running as www-data is strongly recommended because it respects    ║${RESET}"
          echo -e "${BLUE}║  the file ownership set by this script and avoids permission        ║${RESET}"
          echo -e "${BLUE}║  conflicts with files created or modified by WordPress.             ║${RESET}"
          echo -e "${BLUE}║                                                                      ║${RESET}"
          echo -e "${BLUE}║  To update WP-CLI in the future, run:                              ║${RESET}"
          echo -e "${BLUE}║    sudo wp cli update --allow-root                                  ║${RESET}"
          echo -e "${BLUE}║                                                                      ║${RESET}"
          echo -e "${BLUE}║  Full documentation: https://make.wordpress.org/cli/handbook/       ║${RESET}"
          echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════╝${RESET}"
          echo ""
        else
          echo -e "${RED}WP-CLI installation failed.${RESET}"
        fi
      fi
    fi
    # -----------------------------------------------
  fi

  # Set permissions for the DocumentRoot directory
  chown -R www-data:www-data /var/www/$domain
  chmod -R g+rw /var/www/$domain

  # Create the MySQL database and user
  mysql -uroot -p"$db_root_password" -e "CREATE DATABASE $database;" || { echo -e "${RED}Error in creating the database${RESET}"; exit 1; }
  mysql -uroot -p"$db_root_password" -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_password';" || { echo -e "${RED}Error creating MySQL user${RESET}"; }
  mysql -uroot -p"$db_root_password" -e "GRANT ALL PRIVILEGES ON $database.* TO '$db_user'@'localhost';" || { echo -e "${RED}Error assigning permissions to MySQL user${RESET}"; }
  mysql -uroot -p"$db_root_password" -e "FLUSH PRIVILEGES;" || { echo -e "${RED}Error flushing permissions${RESET}"; }

  # Add the domain to /etc/hosts
  echo -e "127.0.0.1 $domain" | tee -a /etc/hosts

  # Restart cloudflared if installed
  if [ -f /usr/local/bin/cloudflared ]; then
    cloudflared service restart
  fi

  # Get current user, check if is in www-data group and, if not, add it
  current_user=$(logname)
  if [ $(groups $current_user | grep -c www-data) -eq 0 ]; then
    usermod -aG www-data $current_user
    newgrp www-data
  fi

  # Restart Apache to apply changes
  service apache2 restart || { echo -e "${RED}Error restarting Apache${RESET}"; exit 1; }

  if $wordpress_download; then
    echo -e "${GREEN}WordPress has been downloaded and configured in the $doc_root folder.${RESET}"
  else
    echo -e "${GREEN}The website has been created in the $doc_root folder.${RESET}"
  fi
}

# ==================================================
# Function to uninstall a site
# ==================================================
uninstall_site() {
  echo ""
  echo -e "Here is the list of removable sites:\n"

  # Gather only base sites, excluding SSL configurations
  sites=($(ls /etc/apache2/sites-available/*.conf | xargs -n 1 basename | sed 's/\.conf$//' | sed 's/-le-ssl$//' | sort -u))

  # If there are no available sites, exit
  if [ ${#sites[@]} -eq 0 ]; then
    echo -e "${RED}There are no sites available for removal.${RESET}"
    exit 1
  fi

  # Show the sites with numbering
  for i in "${!sites[@]}"; do
    echo "$((i + 1)). ${sites[i]}"
  done

  # Ask the user to choose a site
  echo -e "\nEnter the number of the site to remove:"
  read -p "Number: " site_number

  # Verify if the input is valid
  if ! [[ "$site_number" =~ ^[0-9]+$ ]] || [ "$site_number" -lt 1 ] || [ "$site_number" -gt "${#sites[@]}" ]; then
    echo -e "${RED}Invalid choice. Exiting.${RESET}"
    exit 1
  fi

  # Get the chosen domain name
  domain="${sites[$((site_number - 1))]}"
  conf_file="/etc/apache2/sites-available/$domain.conf"
  echo -e "You have selected the domain: $domain"

  # Extract the DocumentRoot from the Apache configuration file
  document_root=$(grep -i "DocumentRoot" "$conf_file" | awk '{print $2}')
  access_log=$(grep -i "CustomLog" "$conf_file" | awk '{print $2}' | head -n 1)
  error_log=$(grep -i "ErrorLog" "$conf_file" | awk '{print $2}' | head -n 1)

  # Check if an SSL configuration file exists
  ssl_conf_file="/etc/apache2/sites-available/$domain-le-ssl.conf"
  if [ -f "$ssl_conf_file" ]; then
    a2dissite "$domain-ssl.conf"
    systemctl reload apache2
    certbot delete --cert-name "$domain" || echo -e "${RED}Error removing the certificate${RESET}"
    rm -f "$ssl_conf_file" "/etc/apache2/sites-enabled/$domain-le-ssl.conf"
    rm -rf "/etc/letsencrypt/live/$domain" "/etc/letsencrypt/archive/$domain" "/etc/letsencrypt/renewal/$domain.conf"
    echo -e "${GREEN}SSL certificate for $domain removed.${RESET}"
  else
    echo -e "${YELLOW}No SSL certificate found for $domain.${RESET}"
  fi

  # Ask whether to remove the associated database
  read -p "Do you want to remove the database associated with $domain? (y/n): " -n 1 -r remove_db
  echo ""
  echo -e "${YELLOW}WARNING: This operation will permanently remove the database and all associated data.${RESET}"
  read -p "Proceed with the removal of the database? (y/n): " -n 1 -r remove_db_check
  echo ""
  if [[ "$remove_db" =~ ^[Yy]$ ]] && [[ "$remove_db_check" =~ ^[Yy]$ ]]; then
    echo -e "Enter the name of the database to remove:"
    read -p "Database name: " database
    if [[ -n "$database" ]]; then
      mysql -uroot -p -e "DROP DATABASE $database;" || { echo -e "${RED}Error in removing the database${RESET}"; }
      echo -e "${GREEN}The database $database has been removed.${RESET}"
    else
      echo -e "${RED}Invalid database name. Operation cancelled.${RESET}"
    fi
  fi

  # Remove the VirtualHost
  a2dissite "$domain.conf"
  rm "$conf_file"
  [ -f "/etc/apache2/sites-enabled/$domain.conf" ] && rm "/etc/apache2/sites-enabled/$domain.conf"

  # Remove the log files
  if [ -n "$access_log" ] && [ -f "$access_log" ]; then
    rm "$access_log"
    echo -e "${GREEN}The access log file has been removed: $access_log${RESET}"
  fi
  if [ -n "$error_log" ] && [ -f "$error_log" ]; then
    rm "$error_log"
    echo -e "${GREEN}The error log file has been removed: $error_log${RESET}"
  fi

  # Remove domain from /etc/hosts
  sed -i "/$domain/d" /etc/hosts

  # Remove DocumentRoot directory
  if [ -n "$document_root" ] && [ -d "$document_root" ]; then
    rm -rf "$document_root"
    echo -e "${GREEN}The DocumentRoot folder has been removed: $document_root${RESET}"
  else
    echo -e "${YELLOW}The DocumentRoot folder was not found or does not exist: $document_root${RESET}"
  fi

  # Restart Apache to apply changes
  service apache2 restart || { echo -e "${RED}Error restarting Apache${RESET}"; exit 1; }

  echo -e "${GREEN}The site $domain has been successfully removed.${RESET}"
}

# ==================================================
# Function to set WordPress permissions
# ==================================================
wordpress_permissions() {
  echo -e "Here is the list of available sites:\n"

  # Gather only base sites, excluding SSL configurations
  sites=($(find /etc/apache2/sites-available -maxdepth 1 -type f -name "*.conf" ! -name "*-ssl.conf" -exec basename {} .conf \; | sort -u))

  if [ ${#sites[@]} -eq 0 ]; then
    echo -e "${RED}There are no available sites to modify permissions for.${RESET}"
    exit 1
  fi

  # Show the sites with numbering
  for i in "${!sites[@]}"; do
    echo "$((i + 1)). ${sites[i]}"
  done

  # Ask the user to choose a site
  echo -e "\nEnter the number of the site to modify permissions for:"
  read -p "Number: " site_number

  # Verify if the input is valid
  if ! [[ "$site_number" =~ ^[0-9]+$ ]] || [ "$site_number" -lt 1 ] || [ "$site_number" -gt "${#sites[@]}" ]; then
    echo -e "${RED}Invalid choice. Exiting.${RESET}"
    exit 1
  fi

  # Get the chosen domain name
  domain="${sites[$((site_number - 1))]}"
  conf_file="/etc/apache2/sites-available/$domain.conf"

  echo -e "You have selected the domain: $domain"

  # Extract the DocumentRoot from the Apache configuration file
  document_root=$(grep -i "DocumentRoot" "$conf_file" | awk '{print $2}')

  WP_OWNER=www-data
  WP_GROUP=www-data
  WP_ROOT=$document_root
  WS_GROUP=www-data

  # Reset to default values
  find ${WP_ROOT} -exec chown ${WP_OWNER}:${WP_GROUP} {} \;
  find ${WP_ROOT} -type d -exec chmod 755 {} \;
  find ${WP_ROOT} -type f -exec chmod 644 {} \;

  # Enable WordPress to manage .htaccess
  touch ${WP_ROOT}/.htaccess
  chgrp ${WS_GROUP} ${WP_ROOT}/.htaccess
  chmod 644 ${WP_ROOT}/.htaccess

  # Enable WordPress to manage wp-content
  find ${WP_ROOT}/wp-content -exec chown -R ${WP_OWNER}:${WS_GROUP} {} \;
  find ${WP_ROOT}/wp-content -type d -exec chmod 775 {} \;
  find ${WP_ROOT}/wp-content -type f -exec chmod 664 {} \;

  # Enable WordPress to manage wp-config.php, if the file exists
  if [ -f ${WP_ROOT}/wp-config.php ]; then
    chown ${WP_OWNER}:${WS_GROUP} ${WP_ROOT}/wp-config.php
    chmod 640 ${WP_ROOT}/wp-config.php
    MSG=""
  else
    MSG="Remember to reset the permissions after completing the WordPress configuration!"
  fi

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}The permissions have been set correctly. $MSG${RESET}"
  else
    echo -e "${RED}An error occurred while setting the permissions.${RESET}"
  fi
}

# ==================================================
# Function to generate an SSL certificate
# ==================================================
generate_certificate() {
  # Check if Certbot is installed, otherwise exit
  if ! [ -x "$(command -v certbot)" ]; then
    echo -e "${RED}Certbot is not installed. Install it before proceeding.${RESET}"
    exit 1
  fi

  echo -e "Here is the list of available sites:\n"
  sites=($(ls /etc/apache2/sites-available/*.conf | xargs -n 1 basename | sed 's/\.conf$//'))

  if [ ${#sites[@]} -eq 0 ]; then
    echo -e "${RED}No sites available.${RESET}"
    exit 1
  fi

  # Show the sites with numbering
  for i in "${!sites[@]}"; do
    echo "$((i + 1)). ${sites[i]}"
  done

  echo -e "\nEnter the site number for which to generate the certificate:"
  read -p "Number: " site_number

  # Verify if the input is valid
  if ! [[ "$site_number" =~ ^[0-9]+$ ]] || [ "$site_number" -lt 1 ] || [ "$site_number" -gt "${#sites[@]}" ]; then
    echo -e "${RED}Invalid choice. Exiting.${RESET}"
    exit 1
  fi

  # Get the chosen domain name
  domain="${sites[$((site_number - 1))]}"
  echo -e "You have selected the domain: $domain"

  # Generate the SSL certificate
  certbot --apache -d $domain

  # Restart Apache to apply the changes
  service apache2 restart || { echo -e "${RED}Error restarting Apache${RESET}"; exit 1; }
}

# ==================================================
# Function to get the list of existing sites
# ==================================================
sites_list() {
  # Detect Apache configuration files
  config_files=$(grep -Rl "DocumentRoot" /etc/apache2/sites-available/)

  if [ -z "$config_files" ]; then
    echo -e "No configuration files with DocumentRoot found."
    return 1
  fi

  # Print the table header with fixed column widths
  echo ""
  printf "%-50s | %-3s | %-70s | %-10s\n" "Domain" "SSL" "DocumentRoot" "WordPress"
  printf "%-50s-+-%-3s-+-%-70s-+-%-10s\n" "$(printf '%.0s-' {1..50})" "---" "$(printf '%.0s-' {1..70})" "----------"

  # List of domains already processed
  processed_domains=()

  # Iterate through each configuration file
  for file in $config_files; do
    domain=$(grep -i "ServerName" "$file" | awk '{print $2}')
    doc_root=$(grep -i "DocumentRoot" "$file" | awk '{print $2}')

    if [ -z "$domain" ] || [ -z "$doc_root" ]; then
      continue
    fi

    # Skip the file if the domain has already been processed
    if [[ " ${processed_domains[@]} " =~ " ${domain} " ]]; then
      continue
    fi

    processed_domains+=("$domain")

    domain=$(echo $domain | cut -c1-50)
    doc_root=$(echo $doc_root | cut -c1-70)

    # Check if the site has a redirect rule to HTTPS
    ssl_enabled="No"
    if grep -qi "RewriteRule" "$file" && grep -qi "https" "$file"; then
      ssl_enabled="Yes"
    fi

    # Check if it is a WordPress site
    is_wordpress="No"
    if [ -f "${doc_root}/wp-config.php" ] && [ -d "${doc_root}/wp-content" ] && [ -d "${doc_root}/wp-includes" ]; then
      is_wordpress="Yes"
    fi

    printf "%-50s | %-3s | %-70s | %-10s\n" "$domain" "$ssl_enabled" "$doc_root" "$is_wordpress"
  done
}

# ==================================================
# Function to execute actions
# ==================================================
execute_action() {
  case $1 in
    1) install_lamp ;;
    2) install_site ;;
    3) uninstall_site ;;
    4) wordpress_permissions ;;
    5) generate_certificate ;;
    6) sites_list ;;
    7)
      echo -e "Exiting the program."
      exit 0
      ;;
    *)
      echo -e "Invalid choice, please try again."
      ;;
  esac
}

# ==================================================
# Main loop
# ==================================================
while true; do
  show_menu
  read -p "Select an option (1-7): " option_choice
  execute_action $option_choice
done
