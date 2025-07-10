# PCAliveCheck Installation Guide

This guide provides instructions for installing and configuring PCAliveCheck on macOS. The package includes scripts for installation, configuration, and uninstallation.

## Prerequisites
- macOS 10.14 or later
- Administrator privileges
- Terminal application
- Stable internet connection

## System Configuration

Before running the installation scripts, you need to enable the necessary system settings for the service to work properly:

1. **Enable Accessibility Permissions**:
   - Open System Settings > Privacy & Security > Privacy > Accessibility
   - Click the + button and add Terminal or iTerm
   - Ensure the checkbox is checked for the terminal application

2. **Allow Background Processes**:
   - Open System Settings > General > Login Items
   - Ensure PCAliveCheck is allowed to run in the background

## Installation

### Method 1: One-line Installation
Run the following command in Terminal:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/install.sh)"
```

### Method 2: Manual Installation
1. Run the configuration script:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/autoA/config.sh)"
   ```
2. Download the installer package:
   ```bash
   curl -O https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/PCAliveCheck-Installer.pkg
   ```
3. Install the package:
   ```bash
   sudo installer -pkg PCAliveCheck-Installer.pkg -target /
   ```
4. The service will start automatically after installation.

## Script Details

### install.sh
This script handles the installation of PCAliveCheck components.

**Features:**
- Runs pre-installation configuration
- Downloads and installs the latest PCAliveCheck package
- Verifies system requirements
- Sets up necessary system configurations
- Starts the PCAliveCheck service

### uninstall.sh
Use this script to completely remove PCAliveCheck from your system.

**Features:**
- Stops the PCAliveCheck service
- Removes all installed components
- Cleans up configuration files

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/uninstall.sh)"
```

## Troubleshooting

### Checking Logs
- System logs: `log show --predicate 'process == "pcAliveCheck"' --last 10m`
- Application logs: `/tmp/pcalivecheck.out.log`
- Error logs: `/tmp/pcalivecheck.err.log`

### Common Issues
1. **Permission Errors**:
   - Run `chmod +x` on the script files before execution
   - Ensure you have administrator privileges

2. **Service Not Running**:
   - Check service status: `launchctl list | grep pcalivecheck`
   - Restart the service: `launchctl load ~/Library/LaunchAgents/ai.hcbu-roundsquare.pcalivecheck.plist`

3. **Accessibility Permissions**:
   - Go to System Settings > Privacy & Security > Privacy > Accessibility
   - Ensure your terminal application has permission

## License and Support
- This software is provided by HCBU.
- Unauthorized copying and distribution is prohibited.
- For support or feature requests, please contact the development team.

---

## Version Information
- Current Version: 1.0.0
- Last Updated: 2025-07-10