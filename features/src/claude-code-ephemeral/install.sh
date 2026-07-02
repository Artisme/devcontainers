#!/usr/bin/env bash
set -e

# Setup formatting for build logs
echo "--> Initializing EPHEMERAL Claude Code environment setup..."

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
# 2. Provision the Ephemeral Configuration Mount Point
# ---------------------------------------------------------------------------
# Unlike the persistent "claude-code" feature, this variant backs
# CLAUDE_CONFIG_DIR with a tmpfs (in-memory) mount declared in
# devcontainer-feature.json -- NOT a named volume. Consequences:
#
#   * Config, credentials, and plugins never touch the host disk.
#   * They live only in RAM while the container is running.
#   * When the container STOPS, the tmpfs is destroyed and every credential is
#     gone. The next start begins empty, so a fresh `claude` login is required.
#
# This is deliberate: on a shared machine, a persistent credential volume could
# be read by anyone who can reach the stopped container. tmpfs removes that
# window entirely.
#
# We still create the directory in the image so the mount has a target. Its
# runtime permissions come from `tmpfs-mode=1777` on the mount, since anything
# we chmod here is masked once the tmpfs is mounted over it at container start.
echo "--> Provisioning ephemeral configuration mount point..."

CONFIG_DIR="/usr/local/claude-config"

mkdir -p "${CONFIG_DIR}"
chmod 777 "${CONFIG_DIR}"

# ---------------------------------------------------------------------------
# 3. Inject Dynamic User Symlink
# ---------------------------------------------------------------------------
# Drop a startup script into profile.d. When a user opens a terminal, this
# ensures their personal ~/.claude directory is symlinked to the tmpfs mount.
# CLAUDE_CONFIG_DIR already moves Claude Code's own config here, but some tools
# (e.g. RTK) write to ~/.claude unconditionally, so the symlink keeps them
# pointed at the same in-memory location Claude Code reads.
echo "--> Configuring dynamic user environment bindings..."

cat << 'EOF' > /etc/profile.d/claude-config-link.sh
# Check if the user's .claude config path exists. If not, link it to the tmpfs.
if [ ! -e "${HOME}/.claude" ]; then
    ln -sf /usr/local/claude-config "${HOME}/.claude"
fi
EOF

# Ensure the profile script is executable
chmod +x /etc/profile.d/claude-config-link.sh

echo "--> Ephemeral Claude Code installation completed. Credentials will be wiped on container stop."
