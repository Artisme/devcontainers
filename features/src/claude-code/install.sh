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
# Create a neutral, system-level directory for the config volume mount.
# CLAUDE_CONFIG_DIR (set in devcontainer-feature.json) points Claude Code's
# entire config tree here, so config, credentials, and plugins persist across
# rebuilds. 777 permissions ensure that regardless of the active container user
# (root, vscode, node, etc.), the CLI can successfully write its config -- the
# directory itself must be writable because Claude Code saves .claude.json via
# an atomic temp-file-then-rename.
echo "--> Provisioning shared configuration directory..."

CONFIG_DIR="/usr/local/claude-config"

mkdir -p "${CONFIG_DIR}"
chmod 777 "${CONFIG_DIR}"

# ---------------------------------------------------------------------------
# 3. Inject Dynamic User Symlink
# ---------------------------------------------------------------------------
# Drop a startup script into profile.d. When a user opens a terminal, this
# ensures their personal ~/.claude directory is symlinked to the persistent
# volume. CLAUDE_CONFIG_DIR already moves Claude Code's own config here, but
# some tools (e.g. RTK) write to ~/.claude unconditionally, so the symlink
# keeps them pointed at the same place Claude Code reads.
echo "--> Configuring dynamic user environment bindings..."

cat << 'EOF' > /etc/profile.d/claude-config-link.sh
# Check if the user's .claude config path exists. If not, link it to the volume.
if [ ! -e "${HOME}/.claude" ]; then
    ln -sf /usr/local/claude-config "${HOME}/.claude"
fi
EOF

# Ensure the profile script is executable
chmod +x /etc/profile.d/claude-config-link.sh

echo "--> Claude Code installation and persistence setup completed successfully."