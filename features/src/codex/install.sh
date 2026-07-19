#!/usr/bin/env bash
set -e

echo "--> Initializing global OpenAI Codex environment setup..."

# ---------------------------------------------------------------------------
# 1. Install Codex
# ---------------------------------------------------------------------------
echo "--> Installing @openai/codex..."
npm install -g @openai/codex@latest

# Feature scripts run as root at build time. Hand the package scope to the
# non-root container user so upgrades do not require a container rebuild.
echo "--> Granting ${_REMOTE_USER:-root} ownership of the install for updates..."
chown -R "${_REMOTE_USER:-root}" "$(npm root -g)/@openai"

# ---------------------------------------------------------------------------
# 2. Configure persistent Codex home
# ---------------------------------------------------------------------------
# CODEX_HOME is set by devcontainer-feature.json. Keeping the full Codex home
# on a named volume preserves configuration, authentication, sessions, skills,
# memories, and logs across container rebuilds.
echo "--> Provisioning shared configuration directory..."

CONFIG_DIR="/usr/local/codex-config"

mkdir -p "${CONFIG_DIR}"
chmod 777 "${CONFIG_DIR}"

# ---------------------------------------------------------------------------
# 3. Bind the conventional user path
# ---------------------------------------------------------------------------
# CODEX_HOME is authoritative, while the symlink supports integrations and
# scripts that still look for ~/.codex directly.
echo "--> Configuring dynamic user environment bindings..."

cat << 'EOF' > /etc/profile.d/codex-config-link.sh
if [ ! -e "${HOME}/.codex" ]; then
    ln -sf /usr/local/codex-config "${HOME}/.codex"
fi
EOF

chmod +x /etc/profile.d/codex-config-link.sh

echo "--> OpenAI Codex installation and persistence setup completed successfully."
