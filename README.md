# Ops Template for Ubuntu

## 🚀 Quick Start

Clone and initialize the workspace with essential tools in one command:

```bash
# Clone to system root and initialize workspace
cd / && git clone https://github.com/AxiosLeo/ubuntu-ops-template.git workspace && cd /workspace && make init-workspace
```

**What `init-workspace` does:**

- ✅ Sets up proper file permissions
- ✅ Updates system packages
- ✅ Installs Git with configuration
- ✅ Prepares development environment

**Next Steps:**

```bash
# Install specific software
make install-docker    # Docker & Docker Compose
make install-nginx     # Nginx web server
make install-nodejs    # Node.js via NVM
make install-python    # Python via Miniconda

# Or install everything at once
make install-all

# Setup complete environments
make setup-dev         # Development environment
make setup-web         # Web server environment
```

## 📦 Installation

### Method 1: Quick Setup with Standalone Script (Recommended)

Download and run the standalone initialization script - no need to clone the repository first:

- Download and run initialization script in one command

> Run this from any directory

```bash
curl -sSL https://raw.githubusercontent.com/AxiosLeo/ubuntu-ops-template/main/scripts/init_workspace.sh | bash
```

- Or download first, then run

```bash
curl -sSL https://raw.githubusercontent.com/AxiosLeo/ubuntu-ops-template/main/scripts/init_workspace.sh -o init_workspace.sh
chmod +x init_workspace.sh
./init_workspace.sh
```

### Method 2: Manual Clone to System Root

Clone this repository to your system root directory and name it `workspace`:

```bash
# Clone to system root directory
sudo git clone https://github.com/axiosleo/ubuntu-ops-template.git /workspace

# Change ownership to current user
sudo chown -R $USER:$USER /workspace

# Navigate to workspace
cd /workspace

# Make scripts executable
chmod +x scripts/*.sh

# Or use Makefile
make make-executable
```

### Method 3: Clone to User Directory

If you prefer to clone to your user directory:

```bash
# Clone to user home directory
git clone https://github.com/axiosleo/ubuntu-ops-template.git ~/workspace

# Navigate to workspace
cd ~/workspace

# Make scripts executable
chmod +x scripts/*.sh
```

## 🚀 Quick Start

> **📍 Important**: Make sure you are in the `/workspace` directory before running any commands below.

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

| Command                | Description                                 |
| ---------------------- | ------------------------------------------- |
| `make help`            | Show all available commands                 |
| `make status`          | Show installation status                    |
| `make install-all`     | Install all available software              |
| `make install-git`     | Install and configure Git                   |
| `make install-docker`  | Install Docker CE and Docker Compose        |
| `make install-nginx`   | Install and configure Nginx                 |
| `make install-nodejs`  | Install Node.js using NVM                   |
| `make install-python`  | Install Python using Miniconda              |
| `make setup-dev`       | Setup complete development environment      |
| `make setup-web`       | Setup web server environment                |
| `make setup-basic`     | Setup basic server essentials               |
| `make update`          | Update system packages                      |
| `make test`            | Test if installed software works            |
| `make clean`           | Clean up temporary files and caches         |
| `make backup-config`   | Backup important configuration files        |
| `make interactive`     | Run interactive installation menu           |
| `make clone-workspace` | Clone project to /workspace directory       |
| `make init-workspace`  | Initialize workspace and install essentials |

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
- Git (for cloning the repository)
- sudo privileges
- Internet connection
- Basic command line knowledge

## 📖 Usage Examples

### Development Environment Setup

```bash
# Navigate to workspace directory
cd /workspace

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
# Navigate to workspace directory
cd /workspace

# Quick web server setup
make setup-web

# Or step by step
make install-nginx
make install-nodejs
make install-docker
```

### System Maintenance

```bash
# Navigate to workspace directory
cd /workspace

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
