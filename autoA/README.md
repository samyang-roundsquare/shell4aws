# AutoA Installation Guide

This guide provides instructions for installing and configuring AutoA on macOS. The package includes scripts for installation, configuration, and uninstallation.

## Prerequisites
- macOS 10.14 or later
- Administrator privileges
- Safari browser
- Stable internet connection

## Safari Configuration

Before running the installation scripts, you need to enable the necessary Safari settings for the AppleScript and JavaScript automation to work properly:

1. **Enable Safari Developer Menu**:
   - Open Safari
   - Go to Safari > Settings (or Preferences) > Advanced
   - Check "Show Develop menu in menu bar"

2. **Enable JavaScript**:
   - Go to Safari > Settings > Security
   - Ensure "Enable JavaScript" is checked

3. **Allow Apple Events**:
   - Open System Settings > Privacy & Security > Automation
   - Find and enable "Safari" for the application that will run the scripts
   - If using Terminal or iTerm, enable it for those applications as well

## Installation

### Method 1: One-line Installation
Run the following command in Terminal:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/autoA/install.sh)"
```

### Method 2: Manual Installation
1. Download the installer package:
   ```bash
   curl -O https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/autoA/AutoA_Installer.pkg
   ```
2. Install the package:
   ```bash
   sudo installer -pkg AutoA_Installer.pkg -target /
   ```
3. Run the configuration script:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/autoA/config.sh)"
   ```

## Script Details

### install.sh
This script handles the installation of AutoA components.

**Features:**
- Downloads and installs the latest AutoA package
- Verifies system requirements
- Runs post-installation configuration
- Cleans up temporary files automatically

### config.sh
This script configures the installed components.

**Features:**
- Sets up necessary system configurations
- Configures Safari settings for automation
- Verifies the installation
- May require user interaction for certain settings

### uninstall.sh
Use this script to completely remove AutoA from your system.

**Features:**
- Removes all installed components
- Cleans up configuration files
- Resets Safari settings if modified by the installation

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/autoA/uninstall.sh)"
```

## Troubleshooting

### Common Issues

1. **Permission Denied Errors**
   - Ensure you're running the script with administrator privileges
   - Run with `sudo` if prompted

2. **Safari Automation Not Working**
   - Verify Safari's automation settings in System Settings > Privacy & Security > Automation
   - Make sure the correct application has permission to control Safari

3. **JavaScript Not Executing**
   - Check Safari's Security settings to ensure JavaScript is enabled
   - Verify no content blockers are interfering with the scripts

## Security Notes

- The installation scripts require internet access to download components
- All downloaded files are verified for integrity
- Temporary files are automatically removed after installation
- The scripts will request necessary permissions during execution

## Support

For additional support, please contact your system administrator or IT support team.

---
*Last Updated: July 9, 2025*
