# Ops Template for Ubuntu

## 🚀 Quick Start

### Using Makefile (Recommended)

```bash
# Show all available commands
make help

# Check system status
make status

# Install all software at once
make install-all

# Install specific software
make install-docker
make install-git
make install-nginx
make install-nodejs
make install-python

# Setup environment profiles
make setup-dev      # Complete development environment
make setup-web      # Web server environment
make setup-basic    # Basic server essentials

# Utility commands
make update         # Update system packages
make test          # Test installed software
make clean         # Clean up caches
make backup-config # Backup configurations
```

### Using Scripts Directly

```bash
# Interactive installation menu
./scripts/install_all.sh

# Individual installations
./scripts/install_docker.sh
./scripts/install_git.sh
./scripts/install_nginx.sh
./scripts/install_nodejs.sh
./scripts/install_python.sh
```

## 📋 Available Commands

| Command               | Description                            |
| --------------------- | -------------------------------------- |
| `make help`           | Show all available commands            |
| `make status`         | Show installation status               |
| `make install-all`    | Install all available software         |
| `make install-git`    | Install and configure Git              |
| `make install-docker` | Install Docker CE and Docker Compose   |
| `make install-nginx`  | Install and configure Nginx            |
| `make install-nodejs` | Install Node.js using NVM              |
| `make install-python` | Install Python using Miniconda         |
| `make setup-dev`      | Setup complete development environment |
| `make setup-web`      | Setup web server environment           |
| `make setup-basic`    | Setup basic server essentials          |
| `make update`         | Update system packages                 |
| `make test`           | Test if installed software works       |
| `make clean`          | Clean up temporary files and caches    |
| `make backup-config`  | Backup important configuration files   |
| `make interactive`    | Run interactive installation menu      |

## Softwares

- Git
- Node.js
- Nginx
- Docker
- Python (Miniconda)

## Server Configuration

1. SSH Configuration

> vi /etc/ssh/sshd_config

```shell
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
```

## 📁 Directory Structure

| Directory      | Description                                                                                |
| -------------- | ------------------------------------------------------------------------------------------ |
| assets         | Static resource files, installation packages, etc.                                         |
| bin            | Startup scripts                                                                            |
| infrastructure | Infrastructure configuration related                                                       |
| scripts        | Server operation related scripts                                                           |
| nginx-config   | Nginx related configuration                                                                |
| temp           | Temporary directory for pulling third-party project source code (GitHub/Gitee) for testing |
| projects       | Self-developed project source code, stored on coding platform                              |
| dist           | Compiled and packaged artifact storage path                                                |

## 🛠️ Script Features

### Enhanced Installation Scripts

All installation scripts now include:

- ✅ **Error Handling**: Automatic error detection and graceful failure
- ✅ **Pre-installation Checks**: Verify if software is already installed
- ✅ **Interactive Prompts**: User-friendly configuration options
- ✅ **Colored Output**: Clear visual feedback with color-coded messages
- ✅ **Logging**: Detailed installation progress and status
- ✅ **Post-installation Verification**: Automatic testing of installations

### Docker Installation (`install_docker.sh`)

- Installs Docker CE and Docker Compose
- Adds current user to docker group
- Enables Docker service
- Provides usage instructions

### Git Installation (`install_git.sh`)

- Installs Git with interactive configuration
- SSH key generation for GitHub/GitLab
- Sets up useful Git defaults
- Credential caching options

### Nginx Installation (`install_nginx.sh`)

- Installs and configures Nginx
- Sets up firewall rules (if ufw available)
- Creates configuration backups
- Provides management commands

### Node.js Installation (`install_nodejs.sh`)

- Installs NVM (Node Version Manager)
- Installs Node.js v22
- Configures npm registry options
- Installs useful global packages (yarn, pnpm, pm2)

### Python Installation (`install_python.sh`)

- Downloads and installs Miniconda
- Creates Python 3.13 environment
- Installs essential packages
- Configures pip mirror options

### All-in-One Installer (`install_all.sh`)

- Interactive menu system
- Selective installation options
- System requirements checking
- Progress tracking

## 🔧 Requirements

- Ubuntu Linux (18.04+)
- sudo privileges
- Internet connection

## 📖 Usage Examples

### Development Environment Setup

```bash
# Quick development setup
make setup-dev

# Or step by step
make install-git
make install-docker
make install-nodejs
make install-python
```

### Web Server Setup

```bash
# Quick web server setup
make setup-web

# Or step by step
make install-nginx
make install-nodejs
make install-docker
```

### System Maintenance

```bash
# Update system
make update

# Check what's installed
make status

# Test installations
make test

# Clean up
make clean

# Backup configs
make backup-config
```
