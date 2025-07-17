#!/bin/bash

# Docker Installation Script for Ubuntu
# This script installs Docker CE and Docker Compose

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

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    log_warn "Docker is already installed: $(docker --version)"
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled"
        exit 0
    fi
fi

log_info "Starting Docker installation..."

# Update package index
log_info "Updating package index..."
sudo apt-get update

# Install required packages
log_info "Installing required packages..."
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Create keyring directory
sudo install -m 0755 -d /etc/apt/keyrings

# Add Docker's official GPG key
log_info "Adding Docker's official GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
log_info "Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
log_info "Updating package index with Docker repository..."
sudo apt-get update

# Install Docker Engine
log_info "Installing Docker Engine..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
log_info "Adding current user to docker group..."
sudo usermod -aG docker $USER

# Start and enable Docker service
log_info "Starting and enabling Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Verify installation
log_info "Verifying Docker installation..."
docker --version
docker compose version

log_info "Docker installation completed successfully!"
log_warn "Please log out and log back in for group changes to take effect."
log_info "You can test Docker with: docker run hello-world"
