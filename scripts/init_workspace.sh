#!/bin/bash

# init_workspace.sh - Standalone workspace initialization script
# Can be downloaded and run directly without cloning the repository first

set -e  # Exit on error

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project repository URL
REPO_URL="https://github.com/AxiosLeo/ubuntu-ops-template.git"
WORKSPACE_DIR="/workspace"

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

# Check system dependencies and requirements
check_deps() {
    print_message $CYAN "Checking system dependencies..."
    
    # Check if it's Ubuntu system
    if [ ! -f /etc/lsb-release ] || ! grep -q "Ubuntu" /etc/lsb-release 2>/dev/null; then
        print_message $YELLOW "Warning: This script is designed for Ubuntu"
    fi
    
    # Check sudo permissions
    if ! sudo -n true 2>/dev/null; then
        print_message $RED "Error: sudo privileges required"
        exit 1
    fi
    
    # Check network connection
    if ! ping -c 1 google.com >/dev/null 2>&1; then
        print_message $YELLOW "Warning: No network connection detected"
    fi
    
    # Check necessary commands
    if ! command_exists git; then
        print_message $YELLOW "Git not installed, will be installed in subsequent steps"
    fi
    
    print_message $GREEN "✓ System check completed"
}

# Install basic Git (if not already installed)
install_basic_git() {
    if ! command_exists git; then
        print_message $BLUE "Installing basic Git..."
        sudo apt update
        sudo apt install -y git
        print_message $GREEN "✓ Basic Git installation completed"
    else
        print_message $GREEN "✓ Git already exists"
    fi
}

# Check if in interactive mode
is_interactive() {
    [[ -t 0 && -t 1 ]]
}

# Clone repository to workspace
clone_workspace() {
    if [ ! -d "$WORKSPACE_DIR" ]; then
        print_message $CYAN "Cloning repository to $WORKSPACE_DIR..."
        sudo git clone "$REPO_URL" "$WORKSPACE_DIR"
        sudo chown -R $USER:$USER "$WORKSPACE_DIR"
        print_message $GREEN "✓ Repository cloned to $WORKSPACE_DIR"
    else
        print_message $YELLOW "⚠ $WORKSPACE_DIR directory already exists"
        print_message $BLUE "Checking existing workspace..."
        
        # Check if it's a git repository
        if [ -d "$WORKSPACE_DIR/.git" ]; then
            if is_interactive; then
                read -p "Update existing repository? (y/N): " -n 1 -r
                echo
                update_repo="$REPLY"
            else
                print_message $CYAN "Non-interactive mode: automatically updating existing repository..."
                update_repo="y"
            fi
            
            if [[ $update_repo =~ ^[Yy]$ ]]; then
                print_message $CYAN "Updating existing repository..."
                cd "$WORKSPACE_DIR"
                git pull origin main || print_message $YELLOW "Cannot update repository, continuing with existing version"
                print_message $GREEN "✓ Repository update completed"
            else
                print_message $YELLOW "Skipping repository update"
            fi
        else
            print_message $YELLOW "Directory exists but is not a git repository, skipping clone operation"
        fi
        
        # Ensure correct directory permissions
        sudo chown -R $USER:$USER "$WORKSPACE_DIR" 2>/dev/null || true
    fi
    
    # Set script permissions (if scripts directory exists)
    if [ -d "$WORKSPACE_DIR/scripts" ]; then
        chmod +x "$WORKSPACE_DIR"/scripts/*.sh 2>/dev/null || print_message $YELLOW "Cannot set script permissions, please check manually"
        print_message $GREEN "✓ Script permissions set"
    else
        print_message $YELLOW "Scripts directory not found, skipping permission setup"
    fi
}

# Update system packages
update_system() {
    print_message $CYAN "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    sudo apt autoremove -y && sudo apt autoclean
    print_message $GREEN "✓ System update completed"
}

# Install make tool
install_make() {
    if ! command_exists make; then
        print_message $CYAN "Installing make tool..."
        sudo apt install -y make build-essential
        print_message $GREEN "✓ make installation completed: $(make --version | head -1)"
    else
        print_message $GREEN "✓ make already exists: $(make --version | head -1)"
    fi
}

# Install and configure Git (using script from repository)
install_git() {
    print_message $CYAN "Installing and configuring Git..."
    if [ -f "$WORKSPACE_DIR/scripts/install_git.sh" ]; then
        cd "$WORKSPACE_DIR"
        chmod +x scripts/install_git.sh
        ./scripts/install_git.sh | exit 0
        print_message $GREEN "✓ Git installation and configuration completed"
    else
        print_message $RED "❌ Git installation script not found"
        exit 1
    fi
}

# Show completion information
show_completion_info() {
    print_message $GREEN "=== Workspace initialization completed! ==="
    echo
    print_message $BLUE "Completed operations:"
    print_message $GREEN "✅ Set proper file permissions"
    print_message $GREEN "✅ Updated system packages"
    print_message $GREEN "✅ Installed make tool"
    print_message $GREEN "✅ Installed and configured Git"
    print_message $GREEN "✅ Prepared development environment"
    echo
    print_message $BLUE "Next steps:"
    print_message $YELLOW "  cd /workspace"
    print_message $YELLOW "  make help                # View all available commands"
    print_message $YELLOW "  make install-docker      # Install Docker"
    print_message $YELLOW "  make install-nodejs      # Install Node.js"
    print_message $YELLOW "  make install-python      # Install Python"
    print_message $YELLOW "  make install-all         # Install all software"
    echo
    print_message $BLUE "Environment configuration options:"
    print_message $YELLOW "  make setup-dev           # Complete development environment"
    print_message $YELLOW "  make setup-web           # Web server environment"
    print_message $YELLOW "  make setup-basic         # Basic server environment"
}

# Main function
main() {
    print_message $CYAN "=== Ubuntu Ops Template Workspace Initialization ==="
    echo
    
    # Check system dependencies
    check_deps
    echo
    
    # Install basic Git
    install_basic_git
    echo
    
    # Clone workspace
    clone_workspace
    echo
    
    # Update system
    update_system
    echo
    
    # Install make tool
    install_make
    echo
    
    # Install and configure Git
    install_git
    echo
    
    # Show completion information
    show_completion_info
}

# Run main function
main "$@"
