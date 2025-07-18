#!/bin/bash

# install_zsh.sh - Script for installing zsh
# Supports multiple Linux distributions and macOS

set -e  # Exit on error

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if zsh is already installed
check_zsh_installed() {
    if command_exists zsh; then
        print_message $GREEN "✓ zsh is already installed, version: $(zsh --version)"
        return 0
    else
        return 1
    fi
}

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$NAME
            DISTRO=$ID
        elif [ -f /etc/redhat-release ]; then
            OS="Red Hat"
            DISTRO="rhel"
        elif [ -f /etc/debian_version ]; then
            OS="Debian"
            DISTRO="debian"
        else
            OS="Unknown Linux"
            DISTRO="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
        DISTRO="macos"
    else
        OS="Unknown"
        DISTRO="unknown"
    fi
}

# Install zsh
install_zsh() {
    print_message $BLUE "Installing zsh..."
    
    case $DISTRO in
        ubuntu|debian)
            print_message $YELLOW "Detected Ubuntu/Debian system, installing with apt..."
            sudo apt update
            sudo apt install -y zsh
            ;;
        centos|rhel|fedora)
            if command_exists dnf; then
                print_message $YELLOW "Detected Fedora/RHEL system, installing with dnf..."
                sudo dnf install -y zsh
            elif command_exists yum; then
                print_message $YELLOW "Detected CentOS/RHEL system, installing with yum..."
                sudo yum install -y zsh
            else
                print_message $RED "❌ dnf or yum package manager not found"
                exit 1
            fi
            ;;
        arch)
            print_message $YELLOW "Detected Arch Linux system, installing with pacman..."
            sudo pacman -S --noconfirm zsh
            ;;
        opensuse*|sles)
            print_message $YELLOW "Detected openSUSE system, installing with zypper..."
            sudo zypper install -y zsh
            ;;
        alpine)
            print_message $YELLOW "Detected Alpine Linux system, installing with apk..."
            sudo apk add zsh
            ;;
        macos)
            if command_exists brew; then
                print_message $YELLOW "Detected macOS system, installing with Homebrew..."
                brew install zsh
            else
                print_message $YELLOW "Detected macOS system, zsh is usually pre-installed"
                print_message $YELLOW "For the latest version, please install Homebrew first: https://brew.sh"
            fi
            ;;
        *)
            print_message $RED "❌ Unsupported operating system: $OS"
            print_message $YELLOW "Please install zsh manually or contact the administrator"
            exit 1
            ;;
    esac
}

# Set zsh as default shell
set_default_shell() {
    local zsh_path=$(which zsh)
    
    if [ -z "$zsh_path" ]; then
        print_message $RED "❌ Cannot find zsh executable"
        return 1
    fi
    
    print_message $BLUE "zsh installation path: $zsh_path"
    
    # Check if zsh is in /etc/shells
    if ! grep -q "$zsh_path" /etc/shells; then
        print_message $YELLOW "Adding zsh to /etc/shells..."
        echo "$zsh_path" | sudo tee -a /etc/shells
    fi
    
    # Ask if user wants to set as default shell
    read -p "Set zsh as default shell? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_message $BLUE "Setting zsh as default shell..."
        chsh -s "$zsh_path"
        print_message $GREEN "✓ zsh has been set as default shell"
        print_message $YELLOW "Note: You need to log out and log back in or restart the terminal for changes to take effect"
    else
        print_message $YELLOW "Skipping default shell setup"
    fi
}

# Install Oh My Zsh (optional)
install_oh_my_zsh() {
    read -p "Install Oh My Zsh? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_message $BLUE "Installing Oh My Zsh..."
        if command_exists curl; then
            sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        elif command_exists wget; then
            sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended
        else
            print_message $RED "❌ curl or wget is required to download Oh My Zsh"
            return 1
        fi
        print_message $GREEN "✓ Oh My Zsh installation completed"
    else
        print_message $YELLOW "Skipping Oh My Zsh installation"
    fi
}

# Main function
main() {
    print_message $BLUE "=== zsh Installation Script ==="
    
    # Check if already installed
    if check_zsh_installed; then
        read -p "zsh is already installed, continue with setup? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_message $YELLOW "Installation cancelled"
            exit 0
        fi
    else
        # Detect operating system
        detect_os
        print_message $BLUE "Detected operating system: $OS ($DISTRO)"
        
        # Install zsh
        install_zsh
        
        # Verify installation
        if check_zsh_installed; then
            print_message $GREEN "✓ zsh installation successful"
        else
            print_message $RED "❌ zsh installation failed"
            exit 1
        fi
    fi
    
    # Set default shell
    set_default_shell
    
    # Optional Oh My Zsh installation
    install_oh_my_zsh
    
    print_message $GREEN "=== Installation Complete ==="
    print_message $YELLOW "Tips:"
    print_message $YELLOW "1. If you set zsh as default shell, please log out and log back in or restart the terminal"
    print_message $YELLOW "2. You can run 'zsh' to switch to zsh immediately"
    print_message $YELLOW "3. Configuration file is located at ~/.zshrc"
}

# Run main function
main "$@"
