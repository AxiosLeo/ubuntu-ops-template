#!/bin/bash

# Python Installation Script using Miniconda
# This script installs Miniconda and sets up Python environment

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

# Configuration
MINICONDA_VERSION="latest"
PYTHON_VERSION="3.13"
ENV_NAME="python3.13"
MINICONDA_DIR="$HOME/miniconda3"
MINICONDA_INSTALLER="$HOME/miniconda3/miniconda.sh"

log_info "Starting Python (Miniconda) installation..."

# Check if Miniconda is already installed
if [ -d "$MINICONDA_DIR" ] && [ -f "$MINICONDA_DIR/bin/conda" ]; then
    log_warn "Miniconda is already installed at $MINICONDA_DIR"
    log_info "Current conda version: $($MINICONDA_DIR/bin/conda --version)"
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled"
        exit 0
    else
        log_warn "Removing existing Miniconda installation..."
        rm -rf "$MINICONDA_DIR"
    fi
fi

# Check if system Python is installed
if command -v python3 &> /dev/null; then
    log_info "System Python3 version: $(python3 --version)"
fi

# Create Miniconda directory
log_info "Creating Miniconda directory..."
mkdir -p ~/miniconda3

# Download Miniconda installer
log_info "Downloading Miniconda installer..."
MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"

# Try to download from official source
if wget --timeout=30 -O "$MINICONDA_INSTALLER" "$MINICONDA_URL"; then
    log_info "Miniconda installer downloaded successfully"
else
    log_error "Failed to download Miniconda installer"
    log_info "Please check your internet connection and try again"
    exit 1
fi

# Verify download
if [ ! -f "$MINICONDA_INSTALLER" ]; then
    log_error "Miniconda installer not found"
    exit 1
fi

# Make installer executable
chmod +x "$MINICONDA_INSTALLER"

# Install Miniconda
log_info "Installing Miniconda..."
bash "$MINICONDA_INSTALLER" -b -u -p "$MINICONDA_DIR"

# Remove installer
log_info "Cleaning up installer..."
rm "$MINICONDA_INSTALLER"

# Initialize conda
log_info "Initializing conda..."
"$MINICONDA_DIR/bin/conda" init bash
"$MINICONDA_DIR/bin/conda" init zsh  # Also initialize for zsh users

# Source conda to make it available in current session
eval "$($MINICONDA_DIR/bin/conda shell.bash hook)"

# Update conda
log_info "Updating conda..."
conda update -n base -c defaults conda -y

# Create Python environment
log_info "Creating Python $PYTHON_VERSION environment: $ENV_NAME"
conda create -n "$ENV_NAME" python="$PYTHON_VERSION" -y

# Activate environment
log_info "Activating environment: $ENV_NAME"
conda activate "$ENV_NAME"

# Install essential packages
log_info "Installing essential Python packages..."
conda install -n "$ENV_NAME" -y \
    pip \
    numpy \
    pandas \
    requests \
    setuptools \
    wheel

# Install additional packages via pip
log_info "Installing additional packages via pip..."
conda run -n "$ENV_NAME" pip install \
    virtualenv \
    poetry \
    black \
    flake8 \
    pytest

# Configure pip (optional)
read -p "Do you want to configure pip to use China mirror? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Configuring pip to use Tencent Cloud mirror..."
    conda run -n "$ENV_NAME" pip config set global.index-url https://mirrors.cloud.tencent.com/pypi/simple
    log_info "Pip mirror configured"
fi

# Display environment information
log_info "Python environment created successfully!"
conda info --envs

log_info "Environment details:"
conda run -n "$ENV_NAME" python --version
conda run -n "$ENV_NAME" pip --version

# Create activation script
ACTIVATE_SCRIPT="$HOME/activate_python.sh"
log_info "Creating activation script: $ACTIVATE_SCRIPT"
cat > "$ACTIVATE_SCRIPT" << EOF
#!/bin/bash
# Activate Python environment
source "$MINICONDA_DIR/etc/profile.d/conda.sh"
conda activate $ENV_NAME
echo "Python environment '$ENV_NAME' activated"
echo "Python version: \$(python --version)"
echo "Pip version: \$(pip --version)"
EOF
chmod +x "$ACTIVATE_SCRIPT"

log_info "Python installation completed successfully!"
log_info ""
log_info "To use Python:"
log_info "1. Restart your terminal or run: source ~/.bashrc"
log_info "2. Activate environment: conda activate $ENV_NAME"
log_info "3. Or use the activation script: source $ACTIVATE_SCRIPT"
log_info ""
log_info "Useful conda commands:"
log_info "  - conda activate $ENV_NAME    # Activate environment"
log_info "  - conda deactivate             # Deactivate environment"
log_info "  - conda info --envs            # List environments"
log_info "  - conda list                   # List packages"
log_info "  - conda install <package>      # Install package"
log_info "  - conda update <package>       # Update package"
log_info "  - conda remove <package>       # Remove package"

log_warn "Please restart your terminal or run 'source ~/.bashrc' to use conda commands."
