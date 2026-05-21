#!/usr/bin/env bash
set -e

# Setup formatting for build logs
echo "--> Initializing global RTK (Rust Token Killer) environment setup..."

# ---------------------------------------------------------------------------
# 1. Install Dependencies
# ---------------------------------------------------------------------------
# The upstream install.sh requires curl + tar to fetch and extract the
# pre-compiled binary tarball from GitHub releases.
if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
    echo "--> Installing curl and tar..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y --no-install-recommends curl ca-certificates tar
        rm -rf /var/lib/apt/lists/*
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache curl ca-certificates tar
    fi
fi

# ---------------------------------------------------------------------------
# 2. Install RTK Binary System-Wide
# ---------------------------------------------------------------------------
# Override the installer's default ($HOME/.local/bin) to install to
# /usr/local/bin so the binary is on PATH for every container user.
echo "--> Installing RTK to /usr/local/bin..."

export RTK_INSTALL_DIR=/usr/local/bin
if [ -n "${VERSION:-}" ] && [ "${VERSION}" != "latest" ]; then
    export RTK_VERSION="${VERSION}"
fi

curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh

# Verify the install resolved to the right binary (there is a name collision
# with reachingforthejack/rtk — see RTK.md).
/usr/local/bin/rtk --version

# ---------------------------------------------------------------------------
# 3. Configure Global Analytics Persistence Directory
# ---------------------------------------------------------------------------
# RTK keeps per-user config under ~/.config/rtk and usage analytics / tee
# logs under ~/.local/share/rtk. Stash both on a named volume so `rtk gain`
# history survives container rebuilds.
echo "--> Provisioning shared RTK data directory..."

DATA_DIR="/usr/local/rtk-data"
mkdir -p "${DATA_DIR}/config" "${DATA_DIR}/share"
chmod -R 777 "${DATA_DIR}"

# ---------------------------------------------------------------------------
# 4. Inject Dynamic User Symlinks
# ---------------------------------------------------------------------------
# When a user opens a terminal, link their personal RTK config + state paths
# to the persistent volume so analytics accumulate across rebuilds regardless
# of the active container user (root, vscode, node, etc.).
echo "--> Configuring dynamic user environment bindings..."

cat << 'EOF' > /etc/profile.d/rtk-data-link.sh
# Ensure parent directories exist before symlinking.
mkdir -p "${HOME}/.config" "${HOME}/.local/share" 2>/dev/null || true

# Link RTK config to the persistent volume.
if [ ! -e "${HOME}/.config/rtk" ]; then
    ln -sf /usr/local/rtk-data/config "${HOME}/.config/rtk"
fi

# Link RTK state/analytics to the persistent volume.
if [ ! -e "${HOME}/.local/share/rtk" ]; then
    ln -sf /usr/local/rtk-data/share "${HOME}/.local/share/rtk"
fi
EOF

chmod +x /etc/profile.d/rtk-data-link.sh

echo "--> RTK installation and persistence setup completed successfully."
