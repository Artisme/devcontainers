#!/usr/bin/env bash
set -e

# Setup formatting for build logs
echo "--> Initializing global Claude Code environment setup..."

# ---------------------------------------------------------------------------
# 1. Install Dependencies
# ---------------------------------------------------------------------------
echo "--> Installing @anthropic-ai/claude-code..."
npm install -g @anthropic-ai/claude-code@latest

# Feature scripts run as root at build time, so npm creates the package
# directory root-owned. Hand it to the non-root container user so Claude Code's
# built-in auto-updater can replace the install in place. Without this, updates
# fail with EACCES and a full container rebuild is required just to upgrade.
echo "--> Granting ${_REMOTE_USER:-root} ownership of the install for self-update..."
chown -R "${_REMOTE_USER:-root}" "$(npm root -g)/@anthropic-ai"

# ---------------------------------------------------------------------------
# 2. Configure Global Persistence Directory
# ---------------------------------------------------------------------------
# CLAUDE_CONFIG_DIR (set in devcontainer-feature.json) points Claude Code's
# whole config tree at the mounted volume, so config, credentials, and plugins
# persist across rebuilds. 777 lets any container user (root, vscode, node)
# read/write it, and the directory itself must be writable because Claude Code
# saves .claude.json via an atomic temp-file-then-rename.
echo "--> Provisioning shared configuration directory..."

CONFIG_DIR="/usr/local/claude-config"

mkdir -p "${CONFIG_DIR}"
chmod 777 "${CONFIG_DIR}"

echo "--> Claude Code installation and persistence setup completed successfully."