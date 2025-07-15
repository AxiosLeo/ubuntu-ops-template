#!/bin/bash

# Podman Installation Script for Ubuntu
# This script installs Podman container engine

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if running as root
# if [[ $EUID -eq 0 ]]; then
#    log_error "This script should not be run as root"
#    exit 1
# fi

# Check Ubuntu version
check_ubuntu_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" != "ubuntu" ]; then
            log_error "This script is designed for Ubuntu only"
            exit 1
        fi
        log_info "Ubuntu version: $VERSION"
    else
        log_error "Cannot determine OS version"
        exit 1
    fi
}

# Check if Podman is already installed
check_existing_installation() {
    if command -v podman &> /dev/null; then
        log_warn "Podman is already installed: $(podman --version)"
        read -p "Do you want to reinstall? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled"
            exit 0
        fi
    fi
}

# Update package index
update_packages() {
    log_step "Updating package index..."
    sudo apt-get update
}

# Install required packages
install_dependencies() {
    log_step "Installing required packages..."
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        software-properties-common
}

# Check if Podman is available in Ubuntu repositories
check_podman_availability() {
    log_step "Checking Podman availability in Ubuntu repositories..."
    
    # Check if podman package is available
    if apt-cache show podman &> /dev/null; then
        log_info "Podman is available in Ubuntu repositories"
        return 0
    else
        log_error "Podman is not available in Ubuntu repositories"
        return 1
    fi
}

# Install Podman
install_podman() {
    log_step "Installing Podman..."
    
    # Install Podman from Ubuntu repositories
    sudo apt-get install -y podman
    
    log_info "Podman installed successfully: $(podman --version)"
}

# Configure Podman for current user
configure_podman() {
    log_step "Configuring Podman for current user..."
    
    # Create podman configuration directory
    mkdir -p ~/.config/containers
    
    # Set up registries configuration
    if [ ! -f ~/.config/containers/registries.conf ]; then
        cat > ~/.config/containers/registries.conf << EOF
[registries.search]
registries = ['docker.io', 'registry.fedoraproject.org', 'registry.access.redhat.com']

[registries.insecure]
registries = []

[registries.block]
registries = []
EOF
        log_info "Registries configuration created"
    else
        log_warn "Registries configuration already exists"
    fi
    
    # Configure storage
    if [ ! -f ~/.config/containers/storage.conf ]; then
        cat > ~/.config/containers/storage.conf << EOF
[storage]
driver = "overlay"
runroot = "/run/user/1000/containers"
graphroot = "/home/$USER/.local/share/containers/storage"

[storage.options]
mount_program = "/usr/bin/fuse-overlayfs"
EOF
        log_info "Storage configuration created"
    else
        log_warn "Storage configuration already exists"
    fi
}

# Display usage information
show_usage_info() {
    echo
    log_info "=== Podman Installation Complete ==="
    echo
    echo -e "${BLUE}Basic Podman commands:${NC}"
    echo "  podman --version                    # Check Podman version"
    echo "  podman pull ubuntu:latest           # Pull an image"
    echo "  podman run -it ubuntu:latest bash   # Run interactive container"
    echo "  podman ps                           # List running containers"
    echo "  podman images                       # List images"
    echo "  podman system info                  # Show system information"
    echo
    echo -e "${BLUE}Podman vs Docker:${NC}"
    echo "  • Podman is daemonless (no background service)"
    echo "  • Compatible with Docker commands (mostly)"
    echo "  • Better security with rootless containers"
    echo "  • Can run as non-root user"
    echo
    echo -e "${BLUE}Configuration files:${NC}"
    echo "  ~/.config/containers/registries.conf   # Registry configuration"
    echo "  ~/.config/containers/storage.conf      # Storage configuration"
    echo
    echo -e "${YELLOW}Note: You may need to log out and log back in for all changes to take effect.${NC}"
}

# Main installation function
main() {
    log_info "Starting Podman installation..."
    echo
    
    # Check system requirements
    check_ubuntu_version
    check_existing_installation
    
    # Installation steps
    update_packages
    install_dependencies
    check_podman_availability
    install_podman
    
    # Configuration
    configure_podman
    
    # Show usage information
    show_usage_info
    
    log_info "Podman installation completed successfully!"
}

# Run main function
main "$@" 
