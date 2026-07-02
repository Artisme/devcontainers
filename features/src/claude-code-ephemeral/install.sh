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
# 2. Ephemeral, In-Memory Configuration
# ---------------------------------------------------------------------------
# Unlike the persistent "claude-code" feature, this variant stores Claude Code's
# entire config tree on /dev/shm -- the in-memory tmpfs that every container
# already mounts. CLAUDE_CONFIG_DIR (set in devcontainer-feature.json) points at
# /dev/shm/claude-config. Consequences:
#
#   * Config, credentials, and plugins never touch the host disk.
#   * They live only in RAM while the container is running.
#   * When the container STOPS, the tmpfs is torn down and every credential is
#     gone. The next start begins empty, so a fresh `claude` login is required.
#
# This is deliberate: on a shared machine, credentials left on disk (a named
# volume, or even a stopped container's writable layer) could be read by anyone
# who reaches the container. Keeping them in RAM removes that window entirely.
#
# NOTE: A Feature cannot declare a tmpfs mount itself -- the devcontainer Feature
# schema only permits mount types "bind" and "volume". Reusing the container's
# existing /dev/shm tmpfs is what lets this feature stay self-contained.
#
# /dev/shm is recreated empty on every container start, so the config directory
# is (re)created at runtime by the feature's postStartCommand, not here at build
# time. A build-time mkdir would be wiped by the first start.
echo "--> Config will live in-memory at /dev/shm/claude-config (created at container start)."

# ---------------------------------------------------------------------------
# 3. Inject Dynamic User Symlink
# ---------------------------------------------------------------------------
# Drop a startup script into profile.d. When a user opens a terminal, this
# ensures their personal ~/.claude directory is symlinked to the in-memory
# config. CLAUDE_CONFIG_DIR already moves Claude Code's own config there, but
# some tools (e.g. RTK) write to ~/.claude unconditionally, so the symlink keeps
# them pointed at the same in-memory location Claude Code reads.
echo "--> Configuring dynamic user environment bindings..."

cat << 'EOF' > /etc/profile.d/claude-config-link.sh
# Ensure the in-memory config dir exists (it lives on /dev/shm, which is
# recreated empty on every container start), then link ~/.claude to it.
mkdir -p /dev/shm/claude-config
chmod 700 /dev/shm/claude-config
if [ ! -e "${HOME}/.claude" ]; then
    ln -sf /dev/shm/claude-config "${HOME}/.claude"
fi
EOF

# Ensure the profile script is executable
chmod +x /etc/profile.d/claude-config-link.sh

echo "--> Ephemeral Claude Code installation completed. Credentials will be wiped on container stop."
