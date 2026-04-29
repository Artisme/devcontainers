#!/usr/bin/env bash
set -e

# Setup formatting for build logs
echo "--> Initializing global Claude Code environment setup..."

# ---------------------------------------------------------------------------
# 1. Install Dependencies
# ---------------------------------------------------------------------------
echo "--> Installing @anthropic-ai/claude-code..."
npm install -g @anthropic-ai/claude-code@latest

# ---------------------------------------------------------------------------
# 2. Configure Global Persistence Directory
# ---------------------------------------------------------------------------
# Create a neutral, system-level directory for the config volume mount.
# 777 permissions ensure that regardless of the active container user 
# (root, vscode, node, etc.), the CLI can successfully write its config.
echo "--> Provisioning shared configuration directory..."

CONFIG_DIR="/usr/local/claude-config"
CONFIG_JSON="/usr/local/claude-config.json"

mkdir -p "${CONFIG_DIR}"
chmod 777 "${CONFIG_DIR}"

touch "${CONFIG_JSON}"
chmod 666 "${CONFIG_JSON}"

# ---------------------------------------------------------------------------
# 3. Inject Dynamic User Symlink
# ---------------------------------------------------------------------------
# Drop a startup script into profile.d. When a user opens a terminal, 
# this ensures their personal ~/.claude directory and ~/.claude.json file
# are symlinked to the persistent volume, preventing token/config loss 
# when the container is rebuilt.
echo "--> Configuring dynamic user environment bindings..."

cat << 'EOF' > /etc/profile.d/claude-config-link.sh
# Check if the user's .claude config path exists. If not, link it to the volume.
if [ ! -e "${HOME}/.claude" ]; then
    ln -sf /usr/local/claude-config "${HOME}/.claude"
fi

# Check if the user's .claude.json config file exists. If not, link it to the volume.
if [ ! -e "${HOME}/.claude.json" ]; then
    ln -sf /usr/local/claude-config.json "${HOME}/.claude.json"
fi
EOF

# Ensure the profile script is executable
chmod +x /etc/profile.d/claude-config-link.sh

echo "--> Claude Code installation and persistence setup completed successfully."
