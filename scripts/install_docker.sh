#!/bin/bash

# Docker Installation Script for Ubuntu
# This script installs Docker CE and Docker Compose

# Note: We'll handle errors manually for better control

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

# Auto-detect or honor explicit USE_CHINA_MIRROR={0|1|auto}. Selects
# Aliyun mirror for the Docker apt repo when china mirrors are in effect.
USE_CHINA_MIRROR="${USE_CHINA_MIRROR:-auto}"
if [ "$USE_CHINA_MIRROR" = "auto" ]; then
    log_info "Probing GitHub reachability (5s) to pick mirror..."
    if curl -sI --connect-timeout 5 --max-time 5 \
            https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh \
            2>/dev/null | grep -q "^HTTP"; then
        USE_CHINA_MIRROR=0
    else
        USE_CHINA_MIRROR=1
    fi
fi
if [ "$USE_CHINA_MIRROR" = "1" ]; then
    DOCKER_REPO_BASE="https://mirrors.aliyun.com/docker-ce/linux/ubuntu"
    log_warn "Mirror mode: china (Docker repo: $DOCKER_REPO_BASE)"
else
    DOCKER_REPO_BASE="https://download.docker.com/linux/ubuntu"
    log_info "Mirror mode: direct (Docker repo: $DOCKER_REPO_BASE)"
fi
export USE_CHINA_MIRROR

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

# Check basic network connectivity. We probe a CN-reachable host so this
# doesn't always warn on china servers (google.com is blocked there).
check_network() {
    log_info "Checking network connectivity..."
    if curl -s --connect-timeout 10 "$DOCKER_REPO_BASE/" > /dev/null 2>&1; then
        log_info "Network connectivity: OK"
        return 0
    else
        log_warn "Network connectivity: Limited (this may cause issues with Docker installation)"
        return 1
    fi
}

# Check network but don't exit on failure
if ! check_network; then
    log_warn "Proceeding with installation despite network limitations..."
fi

# Update package index
log_info "Updating package index..."
if ! sudo apt-get update; then
    log_warn "Package index update failed, but continuing with installation..."
fi

# Install required packages
log_info "Installing required packages..."
if ! sudo apt-get install -y ca-certificates curl gnupg lsb-release; then
    log_error "Failed to install required packages"
    exit 1
fi

# Create keyring directory
sudo install -m 0755 -d /etc/apt/keyrings

# Add Docker's official GPG key with retry mechanism
log_info "Adding Docker's official GPG key..."
add_docker_gpg_key() {
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_info "Attempt $attempt/$max_attempts to download Docker GPG key..."
        
        if curl -fsSL --connect-timeout 30 --max-time 60 "$DOCKER_REPO_BASE/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null; then
            sudo chmod a+r /etc/apt/keyrings/docker.gpg
            log_info "Docker GPG key added successfully"
            return 0
        else
            log_warn "Failed to download Docker GPG key (attempt $attempt/$max_attempts)"
            if [ $attempt -lt $max_attempts ]; then
                log_info "Retrying in 5 seconds..."
                sleep 5
            fi
            ((attempt++))
        fi
    done
    
    log_error "Failed to download Docker GPG key after $max_attempts attempts"
    return 1
}

# Try to add Docker GPG key
if ! add_docker_gpg_key; then
    log_warn "Using alternative method to add Docker repository..."
    # Alternative: Add repository without GPG verification (less secure but works)
    echo "deb [arch=$(dpkg --print-architecture)] $DOCKER_REPO_BASE $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    log_warn "Added Docker repository without GPG verification"
fi

# Add Docker repository (only if GPG key was successfully added)
if [ -f /etc/apt/keyrings/docker.gpg ]; then
    log_info "Adding Docker repository with GPG verification..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] $DOCKER_REPO_BASE \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
else
    log_warn "Docker repository already added without GPG verification"
fi

# Update package index again
log_info "Updating package index with Docker repository..."
if ! sudo apt-get update; then
    log_warn "Package index update with Docker repository failed, but continuing..."
fi

# Install Docker Engine
log_info "Installing Docker Engine..."
if ! sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
    log_warn "Failed to install from Docker repository, trying alternative method..."
    
    # Alternative: Install from Ubuntu repositories
    log_info "Installing Docker from Ubuntu repositories..."
    sudo apt-get install -y docker.io docker-compose
    
    if command -v docker &> /dev/null; then
        log_info "Docker installed successfully from Ubuntu repositories"
    else
        log_error "Failed to install Docker from both sources"
        exit 1
    fi
fi

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

# Clean up any failed installations
cleanup_failed_install() {
    if [ -f /etc/apt/sources.list.d/docker.list ]; then
        log_info "Cleaning up Docker repository configuration..."
        sudo rm -f /etc/apt/sources.list.d/docker.list
    fi
    if [ -f /etc/apt/keyrings/docker.gpg ]; then
        sudo rm -f /etc/apt/keyrings/docker.gpg
    fi
}

# Verify installation
log_info "Verifying Docker installation..."
if command -v docker &> /dev/null; then
    docker --version
    if command -v docker-compose &> /dev/null; then
        docker-compose --version
    elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
        docker compose version
    fi
    
    log_info "Docker installation completed successfully!"
    log_warn "Please log out and log back in for group changes to take effect."
    log_info "You can test Docker with: docker run hello-world"
else
    log_error "Docker installation failed"
    cleanup_failed_install
    exit 1
fi
