#!/bin/bash

# --------------------------------------------------
# setup-dev.sh — Dev environment setup for Red Hat
# Author: Dev Team
# Usage: ./setup-dev.sh
# Only supports RHEL, CentOS Stream, Rocky Linux, etc.
# --------------------------------------------------

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

die() {
    log_error "$1"
    exit 1
}

# Don't run as root
if [[ $EUID -eq 0 ]]; then
    die "Do not run as root. Use your regular user account."
fi

# Check if this is a Red Hat-based system
if ! grep -q "Red Hat\|CentOS\|Rocky\|AlmaLinux" /etc/os-release 2>/dev/null; then
    die "This script only supports Red Hat-based systems (RHEL, CentOS, Rocky, AlmaLinux)."
fi

log_info "Starting local development environment setup on Red Hat..."

# Install EPEL repo (needed for some tools like sqlite3 on minimal RHEL)
if ! dnf list installed epel-release &> /dev/null; then
    log_info "Installing EPEL repository..."
    sudo dnf install -y epel-release || die "Failed to install EPEL repo"
fi

# Update system (optional but good practice)
log_info "Updating system packages..."
sudo dnf update -y || die "Failed to update packages"

# Install required tools
log_info "Installing Git, Curl, Docker, and SQLite..."
sudo dnf install -y git curl docker sqlite || die "Failed to install required packages"

# Enable and start Docker
log_info "Enabling and starting Docker service..."
sudo systemctl enable --now docker || die "Failed to start Docker"

# Add user to docker group
if ! groups "$USER" | grep -qw docker; then
    log_info "Adding $USER to 'docker' group..."
    sudo usermod -aG docker "$USER"
    log_warn "You must log out and back in (or run 'newgrp docker') for Docker group changes to take effect."
fi

# Set up environment file
ENV_FILE="$HOME/.dev_env"
log_info "Creating environment file: $ENV_FILE"

cat > "$ENV_FILE" <<EOF
# Auto-generated dev environment
export APP_ENV=development
export DB_HOST=localhost
EOF

# Source it for the rest of the script
source "$ENV_FILE"

# Clone project
PROJECTS_DIR="$HOME/projects"
mkdir -p "$PROJECTS_DIR"
cd "$PROJECTS_DIR"

REPO_URL="https://github.com/example/sample-app.git"
REPO_NAME="sample-app"

if [[ ! -d "$REPO_NAME" ]]; then
    log_info "Cloning repository: $REPO_NAME"
    git clone "$REPO_URL" || die "Failed to clone repository"
else
    log_info "Repository '$REPO_NAME' already exists. Skipping clone."
fi

# Create test database
DB_FILE="$PROJECTS_DIR/test.db"
if [[ ! -f "$DB_FILE" ]]; then
    log_info "Creating test SQLite database..."
    sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY, name TEXT);"
    log_info "Test database created at: $DB_FILE"
else
    log_info "Test database already exists. Skipping creation."
fi

# Final message
echo
log_info "✅ Setup complete on Red Hat system!"
log_info "Next steps:"
echo "  • Log out and back in (or run 'newgrp docker') to use Docker without sudo"
echo "  • Run 'source ~/.dev_env' to load environment variables"
echo "  • Go to ~/projects/sample-app and start coding!"