#!/bin/bash

# Ubuntu Ops Template - All-in-One Installation Script
# This script provides an interactive menu to install various software packages

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

log_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}================================${NC}"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Available installation scripts
declare -A scripts=(
    [1]="install_git.sh|Git Version Control"
    [2]="install_docker.sh|Docker Container Platform"
    [3]="install_nginx.sh|Nginx Web Server"
    [4]="install_nodejs.sh|Node.js Runtime Environment"
    [5]="install_python.sh|Python with Miniconda"
)

# Function to display menu
show_menu() {
    log_header "Ubuntu Ops Template - Installation Menu"
    echo
    echo -e "${BLUE}Available installations:${NC}"
    echo
    
    for key in $(echo "${!scripts[@]}" | tr ' ' '\n' | sort -n); do
        IFS='|' read -r script_name description <<< "${scripts[$key]}"
        echo -e "  ${YELLOW}$key)${NC} $description"
    done
    
    echo
    echo -e "  ${YELLOW}a)${NC} Install all software"
    echo -e "  ${YELLOW}u)${NC} Update system packages"
    echo -e "  ${YELLOW}q)${NC} Quit"
    echo
}

# Function to run installation script
run_installation() {
    local script_name="$1"
    local description="$2"
    
    local script_path="$SCRIPT_DIR/$script_name"
    
    if [ ! -f "$script_path" ]; then
        log_error "Script not found: $script_path"
        return 1
    fi
    
    if [ ! -x "$script_path" ]; then
        log_warn "Making script executable: $script_path"
        chmod +x "$script_path"
    fi
    
    log_header "Installing: $description"
    echo
    
    if bash "$script_path"; then
        log_info "Successfully installed: $description"
        echo
        read -p "Press Enter to continue..."
    else
        log_error "Failed to install: $description"
        echo
        read -p "Press Enter to continue..."
    fi
}

# Function to update system
update_system() {
    log_header "Updating System Packages"
    echo
    
    log_info "Updating package index..."
    sudo apt update
    
    log_info "Upgrading installed packages..."
    sudo apt upgrade -y
    
    log_info "Removing unnecessary packages..."
    sudo apt autoremove -y
    
    log_info "Cleaning package cache..."
    sudo apt autoclean
    
    log_info "System update completed!"
    echo
    read -p "Press Enter to continue..."
}

# Function to install all software
install_all() {
    log_header "Installing All Software"
    echo
    
    log_warn "This will install all available software packages."
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled"
        return
    fi
    
    # Update system first
    update_system
    
    # Install each software
    for key in $(echo "${!scripts[@]}" | tr ' ' '\n' | sort -n); do
        IFS='|' read -r script_name description <<< "${scripts[$key]}"
        echo
        log_info "Starting installation: $description"
        run_installation "$script_name" "$description"
    done
    
    log_header "All Installations Completed"
    log_info "All software has been installed successfully!"
    echo
    read -p "Press Enter to continue..."
}

# Function to check system requirements
check_requirements() {
    log_info "Checking system requirements..."
    
    # Check if running on Ubuntu
    if [ ! -f /etc/lsb-release ] || ! grep -q "Ubuntu" /etc/lsb-release; then
        log_warn "This script is designed for Ubuntu. Other distributions may not be fully supported."
    fi
    
    # Check if user has sudo privileges
    if ! sudo -n true 2>/dev/null; then
        log_error "This script requires sudo privileges. Please run with a user that has sudo access."
        exit 1
    fi
    
    # Check internet connection
    if ! ping -c 1 google.com &> /dev/null; then
        log_warn "No internet connection detected. Some installations may fail."
    fi
    
    log_info "System requirements check completed."
}

# Main function
main() {
    # Check requirements first
    check_requirements
    
    while true; do
        clear
        show_menu
        
        read -p "Please select an option: " choice
        echo
        
        case $choice in
            [1-5])
                if [[ -n "${scripts[$choice]}" ]]; then
                    IFS='|' read -r script_name description <<< "${scripts[$choice]}"
                    run_installation "$script_name" "$description"
                else
                    log_error "Invalid selection: $choice"
                    read -p "Press Enter to continue..."
                fi
                ;;
            a|A)
                install_all
                ;;
            u|U)
                update_system
                ;;
            q|Q)
                log_info "Goodbye!"
                exit 0
                ;;
            *)
                log_error "Invalid option: $choice"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Handle script interruption
trap 'echo; log_warn "Installation interrupted by user"; exit 1' INT TERM

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 
