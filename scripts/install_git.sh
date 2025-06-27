#!/bin/bash

# Git Installation and Configuration Script
# This script installs Git and sets up basic configuration

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Default Git configuration
DEFAULT_USER_NAME="axiosleo"
DEFAULT_USER_EMAIL="axiosleo@foxmail.com"

log_info "Starting Git installation and configuration..."

# Check if Git is already installed
if command -v git &> /dev/null; then
    log_warn "Git is already installed: $(git --version)"
    read -p "Do you want to reconfigure? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Configuration skipped"
        exit 0
    fi
else
    # Update package index and install Git
    log_info "Updating package index..."
    sudo apt update
    
    log_info "Installing Git..."
    sudo apt install -y git
    
    log_info "Git installed successfully: $(git --version)"
fi

# Configure Git user information
log_info "Configuring Git user information..."

# Prompt for user name
read -p "Enter your Git username [$DEFAULT_USER_NAME]: " USER_NAME
USER_NAME=${USER_NAME:-$DEFAULT_USER_NAME}

# Prompt for user email
read -p "Enter your Git email [$DEFAULT_USER_EMAIL]: " USER_EMAIL
USER_EMAIL=${USER_EMAIL:-$DEFAULT_USER_EMAIL}

# Set Git configuration
git config --global user.name "$USER_NAME"
git config --global user.email "$USER_EMAIL"

# Set additional useful Git configurations
log_info "Setting additional Git configurations..."
git config --global init.defaultBranch main
git config --global core.editor vim
git config --global core.autocrlf input
git config --global pull.rebase false
git config --global push.default simple

# Optional: Set up credential helper
read -p "Do you want to enable Git credential caching? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git config --global credential.helper cache
    git config --global credential.helper 'cache --timeout=3600'
    log_info "Git credential caching enabled (1 hour timeout)"
fi

# Display current configuration
log_info "Current Git configuration:"
git config --list --global | grep -E "(user\.|init\.|core\.|pull\.|push\.|credential\.)"

# Optional: Generate SSH key for GitHub/GitLab
read -p "Do you want to generate an SSH key for Git repositories? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    SSH_KEY_PATH="$HOME/.ssh/id_rsa"
    
    if [ -f "$SSH_KEY_PATH" ]; then
        log_warn "SSH key already exists at $SSH_KEY_PATH"
        read -p "Do you want to generate a new one? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "SSH key generation skipped"
        else
            log_info "Generating new SSH key..."
            ssh-keygen -t rsa -b 4096 -C "$USER_EMAIL" -f "$SSH_KEY_PATH" -N ""
        fi
    else
        log_info "Generating SSH key..."
        mkdir -p ~/.ssh
        ssh-keygen -t rsa -b 4096 -C "$USER_EMAIL" -f "$SSH_KEY_PATH" -N ""
    fi
    
    if [ -f "$SSH_KEY_PATH.pub" ]; then
        log_info "SSH public key generated:"
        cat "$SSH_KEY_PATH.pub"
        log_info ""
        log_info "To add this key to GitHub:"
        log_info "1. Copy the above public key"
        log_info "2. Go to GitHub > Settings > SSH and GPG keys"
        log_info "3. Click 'New SSH key' and paste the key"
        log_info ""
        log_info "To add this key to GitLab:"
        log_info "1. Copy the above public key"
        log_info "2. Go to GitLab > User Settings > SSH Keys"
        log_info "3. Paste the key and save"
    fi
fi

# Test Git installation
log_info "Testing Git installation..."
git --version

log_info "Git installation and configuration completed successfully!"
log_info "User: $USER_NAME <$USER_EMAIL>"

# Display useful Git commands
log_info "Useful Git commands:"
log_info "  - git init                    # Initialize a repository"
log_info "  - git clone <url>             # Clone a repository"
log_info "  - git add .                   # Stage all changes"
log_info "  - git commit -m 'message'     # Commit changes"
log_info "  - git push origin main        # Push to remote"
log_info "  - git pull                    # Pull from remote"
log_info "  - git status                  # Check status"
log_info "  - git log --oneline           # View commit history"
