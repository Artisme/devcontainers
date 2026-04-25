#!/usr/bin/env bash
set -e

# Setup formatting for build logs
echo "--> Initializing global Gemini CLI environment setup..."

# ---------------------------------------------------------------------------
# 1. Install Dependencies
# ---------------------------------------------------------------------------
echo "--> Installing @google/gemini-cli..."
npm install -g @google/gemini-cli@latest

# ---------------------------------------------------------------------------
# 2. Configure Global OAuth Persistence Directory
# ---------------------------------------------------------------------------
# Create a neutral, system-level directory for the OAuth token volume mount.
# 777 permissions ensure that regardless of the active container user 
# (root, vscode, node, etc.), the CLI can successfully write the token.
echo "--> Provisioning shared authentication directory..."

AUTH_DIR="/usr/local/gemini-auth"
mkdir -p "${AUTH_DIR}"
chmod 777 "${AUTH_DIR}"

# ---------------------------------------------------------------------------
# 3. Inject Dynamic User Symlink
# ---------------------------------------------------------------------------
# Drop a startup script into profile.d. When a user opens a terminal, 
# this ensures their personal ~/.gemini directory is symlinked to the 
# persistent volume, preventing token loss when the container is rebuilt.
echo "--> Configuring dynamic user environment bindings..."

cat << 'EOF' > /etc/profile.d/gemini-auth-link.sh
# Check if the user's .gemini config path exists. If not, link it to the volume.
if [ ! -e "${HOME}/.gemini" ]; then
    ln -sf /usr/local/gemini-auth "${HOME}/.gemini"
fi
EOF

# Ensure the profile script is executable
chmod +x /etc/profile.d/gemini-auth-link.sh

echo "--> Gemini CLI installation and persistence setup completed successfully."
