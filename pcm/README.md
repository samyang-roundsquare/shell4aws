# PCAliveCheck & EdgeNode Installation Guide

This guide provides instructions for installing and configuring PCAliveCheck and EdgeNode on macOS. The packages include scripts for installation, configuration, and uninstallation.

## Prerequisites
- macOS 10.14 or later
- Administrator privileges
- Terminal application
- Stable internet connection
- Node.js 14+ (for EdgeNode)

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

### One-line Installation
Run the following command in Terminal to install both PCAliveCheck and EdgeNode:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/install.sh)"
```

### Manual Installation
1. Run the configuration script:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/config.sh)"
   ```
2. Download and install PCAliveCheck:
   ```bash
   curl -O https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/pkg/PCAliveCheck-Installer.pkg
   sudo installer -pkg PCAliveCheck-Installer.pkg -target /
   ```
3. Download and install EdgeNode:
   ```bash
   curl -O https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/pkg/EdgeNode-Installer.pkg
   sudo installer -pkg EdgeNode-Installer.pkg -target /
   ```
4. The services will start automatically after installation.

## Script Details

### install.sh
This script handles the installation of both PCAliveCheck and EdgeNode components.

**Features:**
- Runs pre-installation configuration
- Downloads and installs both PCAliveCheck and EdgeNode packages
- Verifies system requirements
- Sets up necessary system configurations
- Starts both services

### uninstall.sh
Use this script to completely remove PCAliveCheck and/or EdgeNode from your system.

**Usage:**
```bash
# Uninstall PCAliveCheck
sudo /path/to/uninstall.sh ai.hcbu-roundsquare.pcalivecheck

# Uninstall EdgeNode
sudo /path/to/uninstall.sh ai.hcbu-roundsquare.edgenode

# Uninstall both (run both commands)
sudo /path/to/uninstall.sh ai.hcbu-roundsquare.pcalivecheck
sudo /path/to/uninstall.sh ai.hcbu-roundsquare.edgenode
```

**Features:**
- Stops the appropriate service(s)
- Removes all installed components
- Cleans up configuration files and caches
- Handles user-specific data for all users

## Troubleshooting

### Checking Logs
- **PCAliveCheck Logs**:
  - System logs: `log show --predicate 'process == "pcAliveCheck"' --last 10m`
  - Application logs: `/tmp/pcalivecheck.out.log`
  - Error logs: `/tmp/pcalivecheck.err.log`

- **EdgeNode Logs**:
  - Application logs: `/tmp/edgenode.out.log`
  - Error logs: `/tmp/edgenode.err.log`
  - Installation logs: `/tmp/edgenode.install.log`

### Common Issues
1. **Permission Errors**:
   - Run `chmod +x` on the script files before execution
   - Ensure you have administrator privileges
   - Check file ownership in `~/.autoA_edge` for EdgeNode

2. **Service Not Running**:
   - For PCAliveCheck:
     - Check status: `launchctl list | grep pcalivecheck`
     - Restart: `launchctl load ~/Library/LaunchAgents/ai.hcbu-roundsquare.pcalivecheck.plist`
   - For EdgeNode:
     - Check status: `ps aux | grep node`
     - Restart: `cd ~/.autoA_edge && yarn start`

3. **Accessibility Permissions**:
   - Go to System Settings > Privacy & Security > Privacy > Accessibility
   - Ensure your terminal application has permission
   - For EdgeNode, also check Full Disk Access permissions

## License and Support
- This software is provided by HCBU.
- Unauthorized copying and distribution is prohibited.
- For support or feature requests, please contact the development team.

---

## Version Information
- PCAliveCheck: 1.0.0
- EdgeNode: 1.0.0
- Last Updated: 2025-07-13