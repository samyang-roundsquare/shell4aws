#!/bin/bash

# AutoA Installer Script for macOS
# This script will download and install AutoA_Installer.pkg and then run config.sh

set -e  # Exit immediately if a command exits with a non-zero status

# Constants
INSTALLER_URL="https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/autoA/AutoA_Installer.pkg"
INSTALLER_NAME="AutoA_Installer.pkg"
CONFIG_URL="https://raw.githubusercontent.com/samyang-roundsquare/shell4aws/main/autoA/config.sh"

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

# Function to install the package
install_package() {
    local temp_dir=$(mktemp -d)
    local installer_path="${temp_dir}/${INSTALLER_NAME}"
    
    echo "Downloading ${INSTALLER_NAME}..."
    if ! curl -fsSL "${INSTALLER_URL}" -o "${installer_path}"; then
        error_exit "Failed to download ${INSTALLER_NAME}"
    fi
    
    echo "Installing ${INSTALLER_NAME}..."
    if ! sudo installer -pkg "${installer_path}" -target /; then
        error_exit "Failed to install ${INSTALLER_NAME}"
    fi
    
    # Clean up
    rm -rf "${temp_dir}"
    echo -e "${GREEN}Installation completed successfully!${NC}"
}

# Main execution
echo -e "${GREEN}Starting AutoA Installation${NC}"
echo "--------------------------------"

# Run the installation
install_package

# Run config.sh directly from URL
echo "Running configuration script..."
if ! bash -c "$(curl -fsSL "${CONFIG_URL}")"; then
    echo -e "${YELLOW}Warning: Failed to execute config script from ${CONFIG_URL}${NC}"
fi

echo -e "${GREEN}Installation process completed!${NC}"
