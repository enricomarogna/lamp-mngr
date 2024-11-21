# LAMP Manager Script
![Version](https://img.shields.io/badge/Version-1.10.1-blue)
![Tested on](https://img.shields.io/badge/Tested%20on-Ubuntu%2022.04%20LTS-violet)
![Licenza](https://img.shields.io/badge/Licenza-MIT-green)
![GitHub last commit](https://img.shields.io/github/last-commit/enricomarogna/lamp-mngr)


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

Bash script to automate the installation and configuration of a LAMP server (Linux, Apache, MySQL, PHP) on Ubuntu. It allows for quickly setting up a complete hosting environment with support for WordPress sites, permission management, basic MySQL security, and SSL certificate generation using Certbot.

<div class="disclaimer" markdown="1" style="color: red; border-left: 6px solid #c00; padding: 10px; margin-top: 20px;">
   <span style="font-weight: bold;">Warning:</span>
   <p style="margin:0;">
   The script is in Beta phase and may contain errors or bugs. It is recommended to run it in a testing environment before using it in production!
   </p>
</div>

## Features
- **LAMP Server Installation**: Installs and configures Apache, MySQL, PHP, and Certbot with a single command.
- **Apache VirtualHost Configuration**: Creates VirtualHosts for specific sites, including permission management and adding the domain to the `/etc/hosts` file.
- **WordPress Site Setup**: Downloads, unpacks, and configures WordPress with proper security permissions.
- **WordPress Permissions Management**: Correctly configures file and folder permissions for enhanced security.
- **Site Uninstallation**: Removes a specific site, including the Apache VirtualHost, MySQL database, site files, and SSL certificates.
- **SSL Certificates**: Installs and configures SSL certificates for specified domains.
- **List of Installed Sites**: Displays a list of the installed sites.

## Requirements
- **Operating System**: Ubuntu 22.04 LTS (or compatible versions).
- **Root Privileges**: The script must be run with root privileges.

## Usage Instructions
1. Download the script to your Ubuntu server: 

   ```bash
   wget https://raw.githubusercontent.com/enricomarogna/lamp-mngr/refs/heads/main/lamp-mngr.sh
   ```

2. Assign execution and security permissions to the script:

   ```bash
   chmod +x lamp-mngr.sh
   sudo chown root:root lamp-mngr.sh
   sudo chmod 700 lamp-mngr.sh
   ```

3. Run the script:
   
   ```bash
   sudo ./lamp-mngr.sh
   ```

## Main Menu
The script provides a menu interface with the following options:

|#|Option|Description|
|-|-------|-----------|
|1|**Install LAMP Server**|Installs Apache, MySQL, PHP, and Certbot|
|2|**Create a Site**|Creates an Apache VirtualHost and a MySQL database for a site (with an option for WordPress)|
|3|**Uninstall Site**|Removes a specific site, including files, database, Apache VirtualHost, and log files|
|4|**Set WP Permissions**|Configures security permissions for a WordPress site|
|5|**Generate SSL Certificate**|Installs and configures an SSL certificate for a domain|
|6|**List Installed Sites**|Displays a list of installed sites|
|7|**Exit**|Exits the script|

## Technical Details

- **Apache**: Automatic activation of `mod_rewrite` and firewall configuration using `ufw`.
- **MySQL**: Root password configuration, automatic execution of `mysql_secure_installation`, and creation of databases and users.
- **PHP**: Checks the installed PHP version and installs the necessary modules, including `php-curl`, `php-gd`, `php-mbstring`, `php-xml`, `php-zip`, `php-imagick`, `php-intl`, and `php-fdomdocument`.
- **Certbot**: Installation for automated SSL certificate management.

## Security
- The script checks that it is run with root privileges and ensures the permissions are correctly set (`700`) to maintain security.
- MySQL is configured with secure passwords, and basic security operations are performed to minimize vulnerabilities.
- **The script is in Beta phase and may contain errors or bugs. It is recommended to run it in a testing environment before using it in production!**

## Important Notes
- Run the script with caution: Always back up important data before running automated configuration scripts.
- Limitations: The script is designed to be run on Ubuntu 22.04 LTS. It may not work properly on other distributions or versions of Ubuntu.

## Contributing
If you'd like to help improve this script, feel free to create a fork of the project and submit a pull request. Any feedback and suggestions are welcome!

## Author
Created by [Enrico Marogna](https://enricomarogna.com/)

## License
Distributed under the MIT License. See the [LICENSE](https://raw.githubusercontent.com/enricomarogna/lamp-mngr/refs/heads/main/LICENSE.rst) file for more details.

## Support Development
You can support the development of this project with a donation on Ko-fi.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/W7W8166X59)
