#!/bin/bash

# --------------------------------------------------
# setup-dev.sh — Dev environment setup for Red Hat
# Author: Dev Team
# Usage: ./setup-dev.sh
# Only supports RHEL, CentOS Stream, Rocky Linux, etc.
# --------------------------------------------------

set -euo pipefail

# Create log file with script name
SCRIPT_NAME=$(basename "$0" .sh)
LOG_DIR="$HOME/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"

# Redirect all output to log file
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "==============================================="
echo "Log file: $LOG_FILE"
echo "==============================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

# Logging functions with unified format
log() {
    local level=$1 color=$2
    shift 2
    echo -e "${color}[$level]${NC} $*"
}

log_info() { log "INFO" "$GREEN" "$@"; }
log_warn() { log "WARN" "$YELLOW" "$@"; }
log_error() { log "ERROR" "$RED" "$@" >&2; }
die() { log_error "$@"; exit 1; }

# Don't run as root
if [[ $EUID -eq 0 ]]; then
    die "Do not run as root. Use your regular user account."
fi

# Check if this is a Red Hat-based system
if ! grep -q "Red Hat\|CentOS\|Rocky\|AlmaLinux" /etc/os-release 2>/dev/null; then
    die "This script only supports Red Hat-based systems (RHEL, CentOS, Rocky, AlmaLinux)."
fi

# Run command with error handling
run_cmd() {
    local desc=$1
    shift
    log_info "$desc..."
    "$@" || die "Failed: $desc"
}

# Setup repos and packages
setup_repos() {
    ! dnf list installed epel-release &>/dev/null && run_cmd "Installing EPEL repository" sudo dnf install -y epel-release
    run_cmd "Updating system packages" sudo dnf update -y
    run_cmd "Installing dnf-plugins-core" sudo dnf install -y dnf-plugins-core
    run_cmd "Adding Docker repository" sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
}

# Define tools to install with validation
declare -A TOOLS=(
    [git]="git --version"
    [curl]="curl --version"
    [docker-ce]="docker --version"
    [sqlite3]="sqlite3 --version"
)

# Install and validate tools
install_and_validate() {
    local tool=$1 check_cmd=$2
    eval "$check_cmd" &>/dev/null && { log_info "✅ $tool already installed"; return 0; }
    run_cmd "Installing $tool" sudo dnf install -y "$tool"
    eval "$check_cmd" &>/dev/null && log_info "✅ Successfully installed $tool" && return 0
    log_error "❌ Installation failed for $tool"; return 1
}

# Docker and environment setup
docker_setup() {
    run_cmd "Enabling Docker service" sudo systemctl enable --now docker
    if ! id -G "$USER" | grep -qw "docker"; then
        log_info "Adding $USER to docker group..."
        sudo usermod -aG docker "$USER"
        log_warn "Log out and back in (or run 'newgrp docker') for changes to take effect"
    fi
}

setup_env_file() {
    local env_file=$1
    log_info "Creating environment file: $env_file"
    cat > "$env_file" <<'EOF'
export APP_ENV=development
export DB_HOST=localhost
EOF
    [[ -f "$env_file" ]] && source "$env_file" || die "Failed to create $env_file"
}

clone_or_skip() {
    local repo_url=$1 repo_name=$2 dest_dir=$3
    mkdir -p "$dest_dir" && cd "$dest_dir"
    [[ -d "$repo_name" ]] && { log_info "Repository '$repo_name' already exists"; return; }
    run_cmd "Cloning repository: $repo_name" git clone "$repo_url"
}

create_db_if_needed() {
    local db_file=$1
    [[ -f "$db_file" ]] && { log_info "Test database already exists"; return; }
    log_info "Creating test SQLite database..."
    sqlite3 "$db_file" "CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY, name TEXT);"
}

# Main execution
log_info "Starting local development environment setup on Red Hat..."
setup_repos

# Install tools loop
log_info "Installing required tools..."
FAILED_TOOLS=()
for tool in "${!TOOLS[@]}"; do
    install_and_validate "$tool" "${TOOLS[$tool]}" || FAILED_TOOLS+=("$tool")
done
[[ ${#FAILED_TOOLS[@]} -gt 0 ]] && die "Failed to install: ${FAILED_TOOLS[*]}"
log_info "✅ All tools installed successfully"

# Setup Docker, environment, and clone repo
docker_setup
setup_env_file "$HOME/.dev_env"
clone_or_skip "https://github.com/Hemanth26080/dev-env-setup.git" "dev-env-setup" "$HOME/projects"
create_db_if_needed "$HOME/projects/test.db"

echo
log_info "✅ Setup complete on Red Hat system!"
log_info "Next steps:"
echo "  • Log out and back in for docker group changes"
echo "  • Run 'source ~/.dev_env' to load environment variables"
echo "  • Go to ~/projects/dev-env-setup and start coding!"