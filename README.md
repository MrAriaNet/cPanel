## cPanel

This script is for installing cPanel in Iran

## How to use script cPanel.sh

```bash
wget -O cPanel.sh https://raw.githubusercontent.com/MrAriaNet/cPanel/main/cPanel.sh
chmod +x cPanel.sh
bash cPanel.sh
```

## How to use script cPanelConfig.sh

An automated script to install and configure cPanel/WHM. The script is written to help for saving time while setting up a cPanel server for production usage.

## How to Start?
> Copy and execute the following command line through SSH (terminal).

```
curl -Ls raw.githubusercontent.com/MrAriaNet/cPanel/main/cPanelConfig.sh | bash
```

## Supported OS?
> AlmaLinux 8.x/9.x 64bit
> Ubuntu 20.04 LTS

---

### Set PHP Values:
__  __
* max_execution_time = 180
* max_input_time = 180
* max_input_vars = 5000
* memory_limit = 1000M
* post_max_size = 2000M
* upload_max_filesize = 8000M

### Scripts Included:
1. ConfigServer Security & Firewall (CSF)
2. ConfigServer ModSecurity Control (CMS)
3. Imunify360
4. Softaculous
5. WP Toolkit
6. JetBackup V4 / V5
7. LiteSpeed Enterprise Edition
8. CloudLinux Shared OS / Pro

## Author

[Aria](https://github.com/MrAriaNet)
