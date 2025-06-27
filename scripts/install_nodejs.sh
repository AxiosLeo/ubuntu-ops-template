#!/bin/bash

# Node.js Installation Script using NVM
# This script installs NVM and the latest LTS version of Node.js

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

# Node.js version to install
NODE_VERSION="22"

log_info "Starting Node.js installation..."

# Check if Node.js is already installed
if command -v node &> /dev/null; then
    log_warn "Node.js is already installed: $(node -v)"
    read -p "Do you want to reinstall using NVM? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled"
        exit 0
    fi
fi

# Install system Node.js first (optional, for compatibility)
log_info "Installing system Node.js package..."
sudo apt update
sudo apt install -y nodejs npm
log_info "System Node.js version: $(node -v)"

# Check if NVM is already installed
if [ -s "$HOME/.nvm/nvm.sh" ]; then
    log_warn "NVM is already installed"
    source "$HOME/.nvm/nvm.sh"
else
    # Install NVM
    log_info "Installing NVM (Node Version Manager)..."
    
    # Download and install NVM from GitHub (more reliable than gitee mirror)
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    
    # Alternative: Use gitee mirror for China users
    # curl -o- https://gitee.com/AxiosLeo/nvm-proxy/raw/master/v0.39.0/install.sh | bash
    
    # Source NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

# Verify NVM installation
if command -v nvm &> /dev/null; then
    log_info "NVM version: $(nvm --version)"
else
    log_error "NVM installation failed"
    exit 1
fi

# Install Node.js using NVM
log_info "Installing Node.js version $NODE_VERSION using NVM..."
nvm install $NODE_VERSION
nvm use $NODE_VERSION
nvm alias default $NODE_VERSION

# Verify Node.js installation
log_info "Node.js version: $(node -v)"
log_info "NPM version: $(npm -v)"

# Configure npm registry (optional, for China users)
read -p "Do you want to configure npm to use Taobao registry? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Configuring npm registry..."
    npm config set registry https://registry.npmmirror.com
    log_info "NPM registry: $(npm config get registry)"
fi

# Install some useful global packages
log_info "Installing useful global packages..."
npm install -g yarn pnpm pm2

log_info "Node.js installation completed successfully!"
log_info "Available commands:"
log_info "  - node -v"
log_info "  - npm -v"
log_info "  - yarn -v"
log_info "  - pnpm -v"
log_info "  - pm2 -v"
log_warn "Please restart your terminal or run 'source ~/.bashrc' to use NVM commands."
