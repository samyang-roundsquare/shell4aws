#!/bin/bash

# PCAliveCheck Installer Script for macOS
# This script will download and install PCAliveCheck-Installer.pkg

set -e  # Exit immediately if a command exits with a non-zero status

# Constants
CONFIG_URL="https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/config.sh"
INSTALLER_URL="https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/pkg/PCAliveCheck-Installer.pkg"
INSTALLER_NAME="PCAliveCheck-Installer.pkg"
WA_INSTALLER_URL="https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/pcm/pkg/EdgeNode-Installer.pkg"
WA_INSTALLER_NAME="EdgeNode-Installer.pkg"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print error messages
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    error_exit "This script is only supported on macOS."
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo -e "${YELLOW}Warning: It's not recommended to run this script as root.${NC}"
    read -p "Do you want to continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Run config.sh directly from URL
echo "Running configuration script..."
if ! bash -c "$(curl -fsSL "${CONFIG_URL}")"; then
    echo -e "${YELLOW}Warning: Failed to execute config script from ${CONFIG_URL}${NC}"
fi

# Function to install the package
install_package() {
    local temp_dir=$(mktemp -d)
    local installer_path="${temp_dir}/${INSTALLER_NAME}"
    local wa_installer_path="${temp_dir}/${WA_INSTALLER_NAME}"
    
    echo "Downloading ${INSTALLER_NAME}..."
    if ! curl -fsSL "${INSTALLER_URL}" -o "${installer_path}"; then
        error_exit "Failed to download ${INSTALLER_NAME}"
    fi
    
    echo "Installing ${INSTALLER_NAME}..."
    if ! sudo installer -pkg "${installer_path}" -target /; then
        error_exit "Failed to install ${INSTALLER_NAME}"
    fi
    
    echo "Downloading ${WA_INSTALLER_NAME}..."
    if ! curl -fsSL "${WA_INSTALLER_URL}" -o "${wa_installer_path}"; then
        error_exit "Failed to download ${WA_INSTALLER_NAME}"
    fi
    
    echo "Installing ${WA_INSTALLER_NAME}..."
    if ! sudo installer -pkg "${wa_installer_path}" -target /; then
        error_exit "Failed to install ${WA_INSTALLER_NAME}"
    fi
    
    # Clean up
    rm -rf "${temp_dir}"
    echo -e "${GREEN}Installation completed successfully!${NC}"
}

# Main execution
echo -e "${GREEN}Starting PCAliveCheck Installation${NC}"
echo "--------------------------------"

# Run the installation
install_package

echo -e "${GREEN}Installation process completed!${NC}"

