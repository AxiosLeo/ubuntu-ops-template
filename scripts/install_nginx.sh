#!/bin/bash

# Nginx Installation Script for Ubuntu
# This script installs Nginx web server and performs basic configuration

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

# Check if running with sudo privileges
if [[ $EUID -eq 0 ]]; then
   log_warn "Running as root user"
else
   # Check if user can sudo
   if ! sudo -n true 2>/dev/null; then
       log_error "This script requires sudo privileges"
       exit 1
   fi
fi

log_info "Starting Nginx installation..."

# Check if Nginx is already installed
if command -v nginx &> /dev/null; then
    log_warn "Nginx is already installed: $(nginx -v 2>&1)"
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled"
        exit 0
    fi
fi

# Update package index
log_info "Updating package index..."
sudo apt update

# Install Nginx
log_info "Installing Nginx..."
sudo apt install -y nginx

# Start and enable Nginx service
log_info "Starting and enabling Nginx service..."
sudo systemctl start nginx
sudo systemctl enable nginx

# Check Nginx status
log_info "Checking Nginx status..."
sudo systemctl status nginx --no-pager -l

# Configure firewall (if ufw is available)
if command -v ufw &> /dev/null; then
    log_info "Configuring firewall for Nginx..."
    sudo ufw allow 'Nginx Full'
    log_info "Firewall rules updated"
fi

# Create backup of original config
log_info "Creating backup of original configuration..."
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# Set proper permissions for web directory
log_info "Setting up web directory permissions..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# Test Nginx configuration
log_info "Testing Nginx configuration..."
sudo nginx -t

# Display version and status
log_info "Nginx installation completed successfully!"
nginx -v
log_info "Nginx status: $(sudo systemctl is-active nginx)"
log_info "Nginx is enabled: $(sudo systemctl is-enabled nginx)"

# Display useful information
log_info "Useful Nginx commands:"
log_info "  - sudo systemctl start nginx    # Start Nginx"
log_info "  - sudo systemctl stop nginx     # Stop Nginx"
log_info "  - sudo systemctl restart nginx  # Restart Nginx"
log_info "  - sudo systemctl reload nginx   # Reload configuration"
log_info "  - sudo nginx -t                 # Test configuration"
log_info "  - sudo nginx -s reload          # Reload gracefully"

# Display access information
SERVER_IP=$(hostname -I | awk '{print $1}')
log_info "Nginx is running and accessible at:"
log_info "  - http://localhost"
log_info "  - http://$SERVER_IP"
log_info ""
log_info "Configuration files:"
log_info "  - Main config: /etc/nginx/nginx.conf"
log_info "  - Sites available: /etc/nginx/sites-available/"
log_info "  - Sites enabled: /etc/nginx/sites-enabled/"
log_info "  - Document root: /var/www/html"
