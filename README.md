# LAMP Manager Script
![Version](https://img.shields.io/badge/Version-1.11.0-blue)
![Tested on](https://img.shields.io/badge/Tested%20on-Ubuntu%2022.04%20LTS-violet)
![License](https://img.shields.io/badge/License-MIT-green)
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

Bash script to automate the installation and configuration of a LAMP server (Linux, Apache, MySQL, PHP) on Ubuntu. It allows for quickly setting up a complete hosting environment with support for WordPress sites, permission management, basic MySQL security, SSL certificate generation via Certbot, and optional WP-CLI integration.

> [!WARNING]
> The script is in Beta phase and may contain errors or bugs. Always run it in a testing environment before using it in production, and back up any important data beforehand.

---

## Features

- **LAMP Server Installation** — Installs and configures Apache, MySQL, PHP, and Certbot with a single command.
- **Apache VirtualHost Configuration** — Creates VirtualHosts for specific sites, including permission management and automatic addition of the domain to `/etc/hosts`.
- **WordPress Site Setup** — Downloads, unpacks, and configures WordPress with proper security permissions.
- **WP-CLI Support** — Optionally installs WP-CLI during WordPress site creation, with built-in guidance on correct usage.
- **WordPress Permissions Management** — Correctly configures file and folder permissions for enhanced security.
- **Site Uninstallation** — Removes a specific site, including the Apache VirtualHost, MySQL database, site files, and SSL certificates.
- **SSL Certificates** — Installs and configures SSL certificates for specified domains via Certbot.
- **List of Installed Sites** — Displays a summary table of installed sites, with SSL and WordPress status.

---

## Requirements

- **Operating System**: Ubuntu 22.04 LTS (or compatible versions)
- **Root Privileges**: The script must be run as root
- **Script Permissions**: The script file must be owned by root with `700` permissions (enforced at startup)

---

## Usage Instructions

1. Download the script to your Ubuntu server:

   ```bash
   wget https://raw.githubusercontent.com/enricomarogna/lamp-mngr/refs/heads/main/lamp-mngr.sh
   ```

2. Assign execution and security permissions:

   ```bash
   sudo chown root:root lamp-mngr.sh && sudo chmod 700 lamp-mngr.sh
   ```

3. Run the script:

   ```bash
   sudo ./lamp-mngr.sh
   ```

---

## Main Menu

| # | Option | Description |
|---|--------|-------------|
| 1 | **Install LAMP Server** | Installs Apache, MySQL, PHP, and Certbot |
| 2 | **Create a Site** | Creates an Apache VirtualHost and a MySQL database for a site (with optional WordPress + WP-CLI) |
| 3 | **Uninstall Site** | Removes a specific site, including files, database, Apache VirtualHost, and log files |
| 4 | **Set WP Permissions** | Configures security permissions for a WordPress site |
| 5 | **Generate SSL Certificate** | Installs and configures an SSL certificate for a domain |
| 6 | **List Installed Sites** | Displays a list of installed sites |
| 7 | **Exit** | Exits the script |

---

## Technical Details

- **Apache** — Automatic activation of `mod_rewrite` and firewall configuration via `ufw`.
- **MySQL** — Root password setup, automatic execution of `mysql_secure_installation`, creation of databases and dedicated users with scoped privileges.
- **PHP** — Detects the installed PHP version and installs the necessary modules: `php-curl`, `php-gd`, `php-mbstring`, `php-xml`, `php-zip`, `php-imagick`, `php-intl`, `php-fdomdocument`.
- **Certbot** — Installed with the Apache plugin for automated SSL certificate management.
- **WP-CLI** — Optionally installed at `/usr/local/bin/wp` during WordPress site creation. The `.phar` file is validated before installation. If already present, the installation is skipped and the existing version is displayed.

---

## WP-CLI Usage Notes

WP-CLI is installed globally and is available for all WordPress sites on the server. Commands must always be run from the site's DocumentRoot or by specifying the `--path` flag.

**As root** (requires `--allow-root`):
```bash
wp <command> --allow-root --path=/var/www/yourdomain.com
```

**As www-data** (recommended for production):
```bash
sudo -u www-data wp <command> --path=/var/www/yourdomain.com
```

> Running as `www-data` is strongly recommended in production environments. It respects the file ownership set by the script and prevents permission conflicts caused by files created or modified directly by WordPress.

**To update WP-CLI in the future:**
```bash
sudo wp cli update --allow-root
```

Full documentation: [https://make.wordpress.org/cli/handbook/](https://make.wordpress.org/cli/handbook/)

---

## Security

- The script verifies that it is run with root privileges and enforces `700` file permissions on itself before executing any operation.
- MySQL is configured with secure passwords and hardened via `mysql_secure_installation`.
- WordPress file permissions are set to restrict write access to only where strictly necessary (`wp-content`, `.htaccess`, `wp-config.php`).
- WP-CLI commands should be run as `www-data` in production to avoid inadvertently creating root-owned files inside the web root.

> [!CAUTION]
> Always back up important data before running automated configuration scripts. The script is designed for Ubuntu 22.04 LTS and may not work correctly on other distributions or versions.

---

## Changelog

### v1.11.0
- Added optional WP-CLI installation during WordPress site setup
- WP-CLI `.phar` integrity is validated before installation; installation is skipped if WP-CLI is already present
- Post-install info box with `root` vs `www-data` usage notes and update instructions
- Fixed invalid `$` prefix on `Version` variable (bash syntax error)
- Replaced Italian `"Sì"` with `"Yes"` in `sites_list()` for consistent English output
- Translated remaining Italian inline comments to English
- Removed redundant `sudo` calls inside the root-only execution context

### v1.10.2
- Previous release

---

## Contributing

Contributions are welcome! Feel free to fork the repository and submit a pull request. Bug reports, suggestions, and feedback are appreciated.

---

## Author

Created by [Enrico Marogna](https://enricomarogna.com/)

---

## License

Distributed under the MIT License. See the [LICENSE](https://raw.githubusercontent.com/enricomarogna/lamp-mngr/refs/heads/main/LICENSE.rst) file for more details.

---

## Support Development

If you find this project useful, consider [buying me a beer 🍺](https://www.paypal.com/paypalme/enricomarogna/5) — it helps a lot!

[![Donate via PayPal](https://img.shields.io/badge/PayPal-Buy%20me%20a%20beer-00457C?logo=paypal&logoColor=white)](https://www.paypal.com/paypalme/enricomarogna/5)
