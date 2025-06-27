# Ubuntu Ops Template Makefile
# This Makefile provides convenient commands for installing and managing software

.PHONY: help install-all install-git install-docker install-nginx install-nodejs install-python update clean check-deps

# Default target
.DEFAULT_GOAL := help

# Colors for output
RED=\033[0;31m
GREEN=\033[0;32m
YELLOW=\033[1;33m
BLUE=\033[0;34m
CYAN=\033[0;36m
NC=\033[0m # No Color

# Script directory
SCRIPTS_DIR := scripts

# Help target - display available commands
help: ## Show this help message
	@printf "\033[0;36mUbuntu Ops Template - Available Commands\033[0m\n"
	@echo
	@printf "\033[0;34mInstallation Commands:\033[0m\n"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[1;33m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "install|update|setup"
	@echo
	@printf "\033[0;34mUtility Commands:\033[0m\n"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[1;33m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -v -E "install|update|setup"
	@echo
	@printf "\033[0;34mExamples:\033[0m\n"
	@printf "  make install-all     # Install all software\n"
	@printf "  make install-docker  # Install Docker only\n"
	@printf "  make update          # Update system packages\n"
	@printf "  make interactive     # Run interactive installer\n"

# Check dependencies and system requirements
check-deps: ## Check system dependencies and requirements
	@printf "\033[0;36mChecking system dependencies...\033[0m\n"
	@if [ ! -f /etc/lsb-release ] || ! grep -q "Ubuntu" /etc/lsb-release 2>/dev/null; then \
		printf "\033[1;33mWarning: This script is designed for Ubuntu\033[0m\n"; \
	fi
	@if ! sudo -n true 2>/dev/null; then \
		printf "\033[0;31mError: This requires sudo privileges\033[0m\n"; \
		exit 1; \
	fi
	@if ! ping -c 1 google.com >/dev/null 2>&1; then \
		printf "\033[1;33mWarning: No internet connection detected\033[0m\n"; \
	fi
	@printf "\033[0;32mSystem check completed\033[0m\n"

# Update system packages
update: check-deps ## Update system packages
	@printf "\033[0;36mUpdating system packages...\033[0m\n"
	@sudo apt update && sudo apt upgrade -y
	@sudo apt autoremove -y && sudo apt autoclean
	@printf "\033[0;32mSystem update completed\033[0m\n"

# Install all software
install-all: check-deps ## Install all available software
	@printf "\033[0;36mInstalling all software...\033[0m\n"
	@chmod +x $(SCRIPTS_DIR)/install_all.sh
	@$(SCRIPTS_DIR)/install_all.sh

# Interactive installer
interactive: check-deps ## Run interactive installation menu
	@chmod +x $(SCRIPTS_DIR)/install_all.sh
	@$(SCRIPTS_DIR)/install_all.sh

# Install Git
install-git: check-deps ## Install and configure Git
	@printf "\033[0;36mInstalling Git...\033[0m\n"
	@chmod +x $(SCRIPTS_DIR)/install_git.sh
	@$(SCRIPTS_DIR)/install_git.sh
	@printf "\033[0;32mGit installation completed\033[0m\n"

# Install Docker
install-docker: check-deps ## Install Docker CE and Docker Compose
	@printf "\033[0;36mInstalling Docker...\033[0m\n"
	@chmod +x $(SCRIPTS_DIR)/install_docker.sh
	@$(SCRIPTS_DIR)/install_docker.sh
	@printf "\033[0;32mDocker installation completed\033[0m\n"

# Install Nginx
install-nginx: check-deps ## Install and configure Nginx web server
	@printf "\033[0;36mInstalling Nginx...\033[0m\n"
	@chmod +x $(SCRIPTS_DIR)/install_nginx.sh
	@$(SCRIPTS_DIR)/install_nginx.sh
	@printf "\033[0;32mNginx installation completed\033[0m\n"

# Install Node.js
install-nodejs: check-deps ## Install Node.js using NVM
	@printf "\033[0;36mInstalling Node.js...\033[0m\n"
	@chmod +x $(SCRIPTS_DIR)/install_nodejs.sh
	@$(SCRIPTS_DIR)/install_nodejs.sh
	@printf "\033[0;32mNode.js installation completed\033[0m\n"

# Install Python
install-python: check-deps ## Install Python using Miniconda
	@printf "\033[0;36mInstalling Python...\033[0m\n"
	@chmod +x $(SCRIPTS_DIR)/install_python.sh
	@$(SCRIPTS_DIR)/install_python.sh
	@printf "\033[0;32mPython installation completed\033[0m\n"

# Development environment setup
setup-dev: install-git install-docker install-nodejs install-python ## Setup complete development environment
	@printf "\033[0;32mDevelopment environment setup completed!\033[0m\n"

# Web server setup
setup-web: install-nginx install-nodejs install-docker ## Setup web server environment
	@printf "\033[0;32mWeb server environment setup completed!\033[0m\n"

# Basic server setup
setup-basic: update install-git ## Setup basic server with essentials
	@printf "\033[0;32mBasic server setup completed!\033[0m\n"

# Clean up temporary files and caches
clean: ## Clean up temporary files and package caches
	@printf "\033[0;36mCleaning up...\033[0m\n"
	@sudo apt autoremove -y
	@sudo apt autoclean
	@if [ -d ~/miniconda3/pkgs ]; then conda clean --all -y 2>/dev/null || true; fi
	@if command -v docker >/dev/null 2>&1; then docker system prune -f 2>/dev/null || true; fi
	@printf "\033[0;32mCleanup completed\033[0m\n"

# Show system status
status: ## Show installation status of various software
	@printf "\033[0;36mSystem Status:\033[0m\n"
	@echo
	@printf "\033[0;34mOperating System:\033[0m\n"
	@lsb_release -d 2>/dev/null || echo "Not Ubuntu/Debian"
	@echo
	@printf "\033[0;34mInstalled Software:\033[0m\n"
	@printf "Git: "; if command -v git >/dev/null 2>&1; then printf "\033[0;32m✓ $$(git --version)\033[0m\n"; else printf "\033[0;31m✗ Not installed\033[0m\n"; fi
	@printf "Docker: "; if command -v docker >/dev/null 2>&1; then printf "\033[0;32m✓ $$(docker --version)\033[0m\n"; else printf "\033[0;31m✗ Not installed\033[0m\n"; fi
	@printf "Nginx: "; if command -v nginx >/dev/null 2>&1; then printf "\033[0;32m✓ $$(nginx -v 2>&1)\033[0m\n"; else printf "\033[0;31m✗ Not installed\033[0m\n"; fi
	@printf "Node.js: "; if command -v node >/dev/null 2>&1; then printf "\033[0;32m✓ $$(node --version)\033[0m\n"; else printf "\033[0;31m✗ Not installed\033[0m\n"; fi
	@printf "Python: "; if command -v python3 >/dev/null 2>&1; then printf "\033[0;32m✓ $$(python3 --version)\033[0m\n"; else printf "\033[0;31m✗ Not installed\033[0m\n"; fi
	@printf "Conda: "; if command -v conda >/dev/null 2>&1; then printf "\033[0;32m✓ $$(conda --version)\033[0m\n"; else printf "\033[0;31m✗ Not installed\033[0m\n"; fi

# Make scripts executable
make-executable: ## Make all scripts executable
	@printf "\033[0;36mMaking scripts executable...\033[0m\n"
	@chmod +x $(SCRIPTS_DIR)/*.sh
	@printf "\033[0;32mAll scripts are now executable\033[0m\n"

# Backup system configuration
backup-config: ## Backup important system configuration files
	@printf "\033[0;36mCreating configuration backup...\033[0m\n"
	@mkdir -p backup
	@if [ -f /etc/nginx/nginx.conf ]; then sudo cp /etc/nginx/nginx.conf backup/nginx.conf.backup; fi
	@if [ -f ~/.gitconfig ]; then cp ~/.gitconfig backup/gitconfig.backup; fi
	@if [ -f ~/.bashrc ]; then cp ~/.bashrc backup/bashrc.backup; fi
	@printf "\033[0;32mConfiguration backup completed in ./backup/\033[0m\n"

# Test installations
test: ## Test if installed software is working correctly
	@printf "\033[0;36mTesting installed software...\033[0m\n"
	@echo
	@if command -v git >/dev/null 2>&1; then \
		printf "\033[0;34mTesting Git:\033[0m\n"; \
		git --version && printf "\033[0;32m✓ Git is working\033[0m\n" || printf "\033[0;31m✗ Git test failed\033[0m\n"; \
		echo; \
	fi
	@if command -v docker >/dev/null 2>&1; then \
		printf "\033[0;34mTesting Docker:\033[0m\n"; \
		docker --version && printf "\033[0;32m✓ Docker is working\033[0m\n" || printf "\033[0;31m✗ Docker test failed\033[0m\n"; \
		echo; \
	fi
	@if command -v nginx >/dev/null 2>&1; then \
		printf "\033[0;34mTesting Nginx:\033[0m\n"; \
		sudo nginx -t && printf "\033[0;32m✓ Nginx configuration is valid\033[0m\n" || printf "\033[0;31m✗ Nginx test failed\033[0m\n"; \
		echo; \
	fi
	@if command -v node >/dev/null 2>&1; then \
		printf "\033[0;34mTesting Node.js:\033[0m\n"; \
		node --version && npm --version && printf "\033[0;32m✓ Node.js is working\033[0m\n" || printf "\033[0;31m✗ Node.js test failed\033[0m\n"; \
		echo; \
	fi
	@if command -v python3 >/dev/null 2>&1; then \
		printf "\033[0;34mTesting Python:\033[0m\n"; \
		python3 --version && printf "\033[0;32m✓ Python is working\033[0m\n" || printf "\033[0;31m✗ Python test failed\033[0m\n"; \
		echo; \
	fi
