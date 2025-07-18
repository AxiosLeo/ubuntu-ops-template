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

# Error handling function
handle_conda_error() {
    local exit_code=$1
    local command_description="$2"
    
    if [ $exit_code -ne 0 ]; then
        log_warn "$command_description failed with exit code $exit_code"
        
        # Check if it's a TOS error
        if [ $exit_code -eq 1 ]; then
            log_info "Attempting to resolve Terms of Service issues..."
            accept_conda_tos
            return 0  # Continue execution
        fi
        
        return $exit_code
    fi
    return 0
}

# Function to accept conda Terms of Service
accept_conda_tos() {
    log_info "Accepting conda Terms of Service..."
    
    local channels=(
        "https://repo.anaconda.com/pkgs/main"
        "https://repo.anaconda.com/pkgs/r"
    )
    
    for channel in "${channels[@]}"; do
        if command -v conda &> /dev/null; then
            conda tos accept --override-channels --channel "$channel" 2>/dev/null || true
            log_info "Accepted TOS for $channel"
        fi
    done
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
    log_info "Current conda version: $($MINICONDA_DIR/bin/conda --version 2>/dev/null || echo 'Unable to determine version')"
    
    # Check if the target environment already exists
    if [ -d "$MINICONDA_DIR/envs/$ENV_NAME" ]; then
        log_info "Python environment '$ENV_NAME' already exists"
        echo -n "Do you want to reinstall the entire Miniconda? [y/N] (default: N): "
        read -r REPLY
        REPLY=${REPLY:-N}  # Default to N if no input
    else
        echo -n "Miniconda is installed but environment '$ENV_NAME' is missing. Reinstall? [y/N] (default: N): "
        read -r REPLY
        REPLY=${REPLY:-N}  # Default to N if no input
    fi
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled. Using existing installation."
        
        # Still try to create the environment if it doesn't exist
        if [ ! -d "$MINICONDA_DIR/envs/$ENV_NAME" ]; then
            log_info "Creating missing Python environment..."
            eval "$($MINICONDA_DIR/bin/conda shell.bash hook)"
            accept_conda_tos  # Accept TOS before any conda operations
            conda create -n "$ENV_NAME" python="$PYTHON_VERSION" -y
            log_info "Environment created successfully!"
        fi
        
        # Skip to the end to show usage information
        conda_installed=true
    else
        log_warn "Removing existing Miniconda installation..."
        rm -rf "$MINICONDA_DIR"
        conda_installed=false
    fi
else
    conda_installed=false
fi

# Only proceed with installation if not using existing installation
if [ "$conda_installed" != "true" ]; then
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

    # Accept Terms of Service before any operations
    accept_conda_tos

    # Update conda with error handling
    log_info "Updating conda..."
    set +e  # Temporarily disable exit on error
    conda update -n base -c defaults conda -y
    conda_update_exit_code=$?
    set -e  # Re-enable exit on error
    
    handle_conda_error $conda_update_exit_code "Conda update"

    # Create Python environment
    log_info "Creating Python $PYTHON_VERSION environment: $ENV_NAME"
    set +e
    conda create -n "$ENV_NAME" python="$PYTHON_VERSION" -y
    create_env_exit_code=$?
    set -e
    
    if [ $create_env_exit_code -ne 0 ]; then
        handle_conda_error $create_env_exit_code "Environment creation"
        # Retry environment creation
        log_info "Retrying environment creation..."
        conda create -n "$ENV_NAME" python="$PYTHON_VERSION" -y
    fi

    # Activate environment
    log_info "Activating environment: $ENV_NAME"
    conda activate "$ENV_NAME"

    # Install essential packages with error handling
    log_info "Installing essential Python packages..."
    set +e
    conda install -n "$ENV_NAME" -y \
        pip \
        numpy \
        pandas \
        requests \
        setuptools \
        wheel
    install_exit_code=$?
    set -e
    
    if [ $install_exit_code -ne 0 ]; then
        log_warn "Some packages failed to install via conda, trying with reduced package set..."
        conda install -n "$ENV_NAME" -y pip setuptools wheel || true
    fi

    # Install additional packages via pip with error handling
    log_info "Installing additional packages via pip..."
    set +e
    conda run -n "$ENV_NAME" pip install \
        virtualenv \
        poetry \
        black \
        flake8 \
        pytest
    pip_install_exit_code=$?
    set -e
    
    if [ $pip_install_exit_code -ne 0 ]; then
        log_warn "Some pip packages failed to install, continuing..."
    fi

    # Configure pip (optional)
    echo -n "Do you want to configure pip to use China mirror? [y/N] (default: N): "
    read -r REPLY
    REPLY=${REPLY:-N}
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Configuring pip to use Tencent Cloud mirror..."
        conda run -n "$ENV_NAME" pip config set global.index-url https://mirrors.cloud.tencent.com/pypi/simple
        log_info "Pip mirror configured"
    fi
fi

# Re-source conda to ensure it's available
eval "$($MINICONDA_DIR/bin/conda shell.bash hook)" 2>/dev/null || true

# Display environment information
log_info "Python environment information:"
conda info --envs 2>/dev/null || log_warn "Could not display conda environments"

log_info "Environment details:"
if conda run -n "$ENV_NAME" python --version 2>/dev/null; then
    conda run -n "$ENV_NAME" python --version
    conda run -n "$ENV_NAME" pip --version 2>/dev/null || echo "Pip not available"
else
    log_warn "Could not verify Python installation in environment $ENV_NAME"
fi

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

# Detect current shell and provide appropriate instructions
if [[ "$SHELL" == *"zsh"* ]]; then
    log_info "1. Restart your terminal or run: source ~/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    log_info "1. Restart your terminal or run: source ~/.bashrc"
else
    log_info "1. Restart your terminal or source your shell's configuration file"
fi

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

# Provide shell-specific restart instructions
if [[ "$SHELL" == *"zsh"* ]]; then
    log_warn "Please restart your terminal or run 'source ~/.zshrc' to use conda commands in zsh."
elif [[ "$SHELL" == *"bash"* ]]; then
    log_warn "Please restart your terminal or run 'source ~/.bashrc' to use conda commands."
else
    log_warn "Please restart your terminal to use conda commands, or check your shell's configuration file."
fi
