#!/bin/bash

# init_workspace.sh - Standalone workspace initialization script
# Can be downloaded and run directly without cloning the repository first

set -e  # Exit on error

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Non-interactive apt wrapper to avoid debconf/needrestart TUI prompts
# (e.g. the sshd_config conffile dialog when upgrading openssh-server).
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export NEEDRESTART_SUSPEND=1

apt_quiet() {
    sudo -E DEBIAN_FRONTEND=noninteractive \
        NEEDRESTART_MODE=a NEEDRESTART_SUSPEND=1 \
        apt-get \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confnew" \
        -o DPkg::Lock::Timeout=300 \
        -y "$@"
}

# Force-release dpkg/apt locks. This script is meant for fresh server
# initialization, so it's safe to kill any apt/dpkg process holding the
# lock -- typically a stale apt left behind by a previously interrupted
# run (e.g. user Ctrl+C on a debconf TUI), or the system's
# unattended-upgrades. After killing we run `dpkg --configure -a` to
# repair any half-done dpkg state.
#
# Strategy:
#   1. systemctl stop the system-managed apt timers/services (politely)
#   2. fuser the four lock files to discover ALL holding PIDs
#   3. SIGTERM holders, wait up to 10s
#   4. Still held -> SIGKILL, wait up to 10s
#   5. Still held -> bail with diagnostics
#   6. dpkg --configure -a to repair interrupted state
#
# We only `stop` services for this run (no `systemctl disable`); they
# will come back on next boot.
disable_apt_locks() {
    print_message $CYAN "Releasing apt/dpkg locks..."

    local locks=(
        /var/lib/dpkg/lock-frontend
        /var/lib/dpkg/lock
        /var/lib/apt/lists/lock
        /var/cache/apt/archives/lock
    )

    _locks_held() {
        local f
        for f in "${locks[@]}"; do
            sudo fuser "$f" >/dev/null 2>&1 && return 0
        done
        return 1
    }

    _signal_holders() {
        local sig=$1 lock pid pids cmd
        for lock in "${locks[@]}"; do
            [ -e "$lock" ] || continue
            pids=$(sudo fuser "$lock" 2>/dev/null | grep -oE '[0-9]+' | sort -u)
            for pid in $pids; do
                cmd=$(ps -p "$pid" -o comm= 2>/dev/null | tr -d ' ' || echo '?')
                print_message $YELLOW "  Sending SIG${sig#-} to PID ${pid} (${cmd}) holding ${lock}"
                sudo kill "$sig" "$pid" 2>/dev/null || true
            done
        done
    }

    local svc
    for svc in unattended-upgrades.service apt-daily.timer apt-daily-upgrade.timer apt-daily.service apt-daily-upgrade.service; do
        if systemctl list-unit-files "$svc" >/dev/null 2>&1; then
            sudo systemctl stop "$svc" 2>/dev/null || true
        fi
    done

    if ! _locks_held; then
        print_message $GREEN "  done (locks were already free)"
        return 0
    fi

    local waited

    _signal_holders -TERM
    waited=0
    while _locks_held && [ "$waited" -lt 10 ]; do
        sleep 1
        waited=$((waited + 1))
    done

    if _locks_held; then
        print_message $YELLOW "  Locks still held after SIGTERM; escalating to SIGKILL..."
        _signal_holders -KILL
        waited=0
        while _locks_held && [ "$waited" -lt 10 ]; do
            sleep 1
            waited=$((waited + 1))
        done
    fi

    if _locks_held; then
        print_message $RED "Could not release apt/dpkg lock even after SIGKILL."
        print_message $YELLOW "  Inspect: sudo lsof /var/lib/dpkg/lock-frontend"
        exit 1
    fi

    print_message $CYAN "  Repairing dpkg state with 'dpkg --configure -a'..."
    sudo DEBIAN_FRONTEND=noninteractive dpkg --configure -a >/dev/null 2>&1 || true

    print_message $GREEN "  done"
}

# Detect whether to route GitHub downloads via a China-friendly proxy.
# Honors explicit USE_CHINA_MIRROR={0|1|auto}; default auto probes the
# network and decides. Sets GH_PROXY to either "" or "https://ghfast.top/"
# and exports USE_CHINA_MIRROR so child scripts skip re-probing.
GH_PROXY=""
detect_china_mirror() {
    USE_CHINA_MIRROR="${USE_CHINA_MIRROR:-auto}"
    if [ "$USE_CHINA_MIRROR" = "auto" ]; then
        print_message $CYAN "Probing GitHub reachability (5s) to pick mirror..."
        if curl -sI --connect-timeout 5 --max-time 5 \
                https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh \
                2>/dev/null | grep -q "^HTTP"; then
            USE_CHINA_MIRROR=0
        else
            USE_CHINA_MIRROR=1
        fi
    fi
    if [ "$USE_CHINA_MIRROR" = "1" ]; then
        GH_PROXY="https://ghfast.top/"
        print_message $YELLOW "  Mirror mode: china (GH_PROXY=${GH_PROXY})"
        print_message $YELLOW "  Override with USE_CHINA_MIRROR=0 to force direct GitHub"
    else
        GH_PROXY=""
        print_message $GREEN "  Mirror mode: direct (no proxy)"
    fi
    export USE_CHINA_MIRROR
}

# Project repository URL (GH_PROXY is prepended at clone time, not here,
# because GH_PROXY is only known after detect_china_mirror runs).
REPO_URL="https://github.com/AxiosLeo/ubuntu-ops-template.git"
WORKSPACE_DIR="/workspace"

# Print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check system dependencies and requirements
check_deps() {
    print_message $CYAN "Checking system dependencies..."
    
    # Check if it's Ubuntu system
    if [ ! -f /etc/lsb-release ] || ! grep -q "Ubuntu" /etc/lsb-release 2>/dev/null; then
        print_message $YELLOW "Warning: This script is designed for Ubuntu"
    fi
    
    # Check sudo permissions
    if ! sudo -n true 2>/dev/null; then
        print_message $RED "Error: sudo privileges required"
        exit 1
    fi
    
    # Check network connection
    if ! ping -c 1 google.com >/dev/null 2>&1; then
        print_message $YELLOW "Warning: No network connection detected"
    fi
    
    # Check necessary commands
    if ! command_exists git; then
        print_message $YELLOW "Git not installed, will be installed in subsequent steps"
    fi
    
    print_message $GREEN "✓ System check completed"
}

# Install basic Git (if not already installed)
install_basic_git() {
    if ! command_exists git; then
        print_message $BLUE "Installing basic Git..."
        apt_quiet update
        apt_quiet install git
        print_message $GREEN "✓ Basic Git installation completed"
    else
        print_message $GREEN "✓ Git already exists"
    fi
}

# Check if in interactive mode
is_interactive() {
    [[ -t 0 && -t 1 ]]
}

# Clone repository to workspace
clone_workspace() {
    if [ ! -d "$WORKSPACE_DIR" ]; then
        print_message $CYAN "Cloning repository to $WORKSPACE_DIR..."
        sudo git clone "${GH_PROXY}${REPO_URL}" "$WORKSPACE_DIR"
        sudo chown -R $USER:$USER "$WORKSPACE_DIR"
        print_message $GREEN "✓ Repository cloned to $WORKSPACE_DIR"
    else
        print_message $YELLOW "⚠ $WORKSPACE_DIR directory already exists"
        print_message $BLUE "Checking existing workspace..."
        
        # Check if it's a git repository
        if [ -d "$WORKSPACE_DIR/.git" ]; then
            if is_interactive; then
                read -p "Update existing repository? (y/N): " -n 1 -r
                echo
                update_repo="$REPLY"
            else
                print_message $CYAN "Non-interactive mode: automatically updating existing repository..."
                update_repo="y"
            fi
            
            if [[ $update_repo =~ ^[Yy]$ ]]; then
                print_message $CYAN "Updating existing repository..."
                cd "$WORKSPACE_DIR"
                git pull origin main || print_message $YELLOW "Cannot update repository, continuing with existing version"
                print_message $GREEN "✓ Repository update completed"
            else
                print_message $YELLOW "Skipping repository update"
            fi
        else
            print_message $YELLOW "Directory exists but is not a git repository, skipping clone operation"
        fi
        
        # Ensure correct directory permissions
        sudo chown -R $USER:$USER "$WORKSPACE_DIR" 2>/dev/null || true
    fi
    
    # Set script permissions (if scripts directory exists)
    if [ -d "$WORKSPACE_DIR/scripts" ]; then
        chmod +x "$WORKSPACE_DIR"/scripts/*.sh 2>/dev/null || print_message $YELLOW "Cannot set script permissions, please check manually"
        print_message $GREEN "✓ Script permissions set"
    else
        print_message $YELLOW "Scripts directory not found, skipping permission setup"
    fi
}

# Backup critical config files that apt upgrade may overwrite under
# the --force-confnew strategy (most notably /etc/ssh/sshd_config).
# Backups are written next to the original file with a .bak.<timestamp>
# suffix so they're easy to find and restore.
BACKUP_TIMESTAMP=""
BACKUP_PATHS=()

backup_critical_configs() {
    BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    local files=(
        "/etc/ssh/sshd_config"
        "/etc/ssh/ssh_config"
    )

    print_message $CYAN "Backing up critical config files before upgrade..."
    BACKUP_PATHS=()
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            local backup="${file}.bak.${BACKUP_TIMESTAMP}"
            if sudo cp -a "$file" "$backup" 2>/dev/null; then
                print_message $GREEN "  ✓ ${file} -> ${backup}"
                BACKUP_PATHS+=("$backup")
            else
                print_message $YELLOW "  ⚠ Failed to backup ${file}"
            fi
        fi
    done

    if [ ${#BACKUP_PATHS[@]} -eq 0 ]; then
        print_message $YELLOW "  (no critical config files found to backup)"
    fi
}

# Update system packages
update_system() {
    print_message $CYAN "Updating system packages..."
    backup_critical_configs
    apt_quiet update && apt_quiet upgrade
    apt_quiet autoremove && apt_quiet autoclean
    print_message $GREEN "✓ System update completed"
}

# Install make tool
install_make() {
    if ! command_exists make; then
        print_message $CYAN "Installing make tool..."
        apt_quiet install make build-essential
        print_message $GREEN "✓ make installation completed: $(make --version | head -1)"
    else
        print_message $GREEN "✓ make already exists: $(make --version | head -1)"
    fi
}

# Install and configure Git (using script from repository)
install_git() {
    print_message $CYAN "Installing and configuring Git..."
    if [ -f "$WORKSPACE_DIR/scripts/install_git.sh" ]; then
        cd "$WORKSPACE_DIR"
        chmod +x scripts/install_git.sh
        ./scripts/install_git.sh | exit 0
        print_message $GREEN "✓ Git installation and configuration completed"
    else
        print_message $RED "❌ Git installation script not found"
        exit 1
    fi
}

# Show completion information
show_completion_info() {
    print_message $GREEN "=== Workspace initialization completed! ==="
    echo
    print_message $BLUE "Completed operations:"
    print_message $GREEN "✅ Set proper file permissions"
    print_message $GREEN "✅ Updated system packages"
    print_message $GREEN "✅ Installed make tool"
    print_message $GREEN "✅ Installed and configured Git"
    print_message $GREEN "✅ Prepared development environment"
    echo
    print_message $BLUE "Next steps:"
    print_message $YELLOW "  cd /workspace"
    print_message $YELLOW "  make help                # View all available commands"
    print_message $YELLOW "  make install-docker      # Install Docker"
    print_message $YELLOW "  make install-nodejs      # Install Node.js"
    print_message $YELLOW "  make install-python      # Install Python"
    print_message $YELLOW "  make install-all         # Install all software"
    echo
    print_message $BLUE "Environment configuration options:"
    print_message $YELLOW "  make setup-dev           # Complete development environment"
    print_message $YELLOW "  make setup-web           # Web server environment"
    print_message $YELLOW "  make setup-basic         # Basic server environment"

    if [ ${#BACKUP_PATHS[@]} -gt 0 ]; then
        echo
        print_message $BLUE "Pre-upgrade config backups (timestamp ${BACKUP_TIMESTAMP}):"
        for path in "${BACKUP_PATHS[@]}"; do
            print_message $YELLOW "  ${path}"
        done
        print_message $CYAN "  Restore example: sudo cp -a ${BACKUP_PATHS[0]} ${BACKUP_PATHS[0]%.bak.*}"
    fi
}

# Main function
main() {
    print_message $CYAN "=== Ubuntu Ops Template Workspace Initialization ==="
    echo
    
    # Check system dependencies
    check_deps
    echo
    
    # Pick GitHub mirror (probes or honors USE_CHINA_MIRROR env)
    detect_china_mirror
    echo
    
    # Release apt/dpkg locks held by unattended-upgrades or apt-daily*
    disable_apt_locks
    echo
    
    # Install basic Git
    install_basic_git
    echo
    
    # Clone workspace
    clone_workspace
    echo
    
    # Update system
    update_system
    echo
    
    # Install make tool
    install_make
    echo
    
    # Install and configure Git
    install_git
    echo
    
    # Show completion information
    show_completion_info
}

# Run main function
main "$@"
