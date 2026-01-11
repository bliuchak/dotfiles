#!/usr/bin/env bash
# Setup ssh-agent using systemd user service (recommended for Arch)

set -euo pipefail

echo "Setting up ssh-agent via systemd user service..."

# Enable and start the ssh-agent service
systemctl --user enable ssh-agent
systemctl --user start ssh-agent

echo "ssh-agent service enabled and started"

# Add SSH_AUTH_SOCK to ~/.zshrc if not already present with correct value
ZSHRC="$HOME/.zshrc"
# shellcheck disable=SC2016 # Intentionally using single quotes to preserve $XDG_RUNTIME_DIR literal
SSH_SOCK_LINE='export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"'

if [ -f "$ZSHRC" ] && grep -qF "$SSH_SOCK_LINE" "$ZSHRC"; then
    echo "SSH_AUTH_SOCK already correctly configured in $ZSHRC"
else
    {
        echo ""
        echo "# ssh-agent socket"
        echo "$SSH_SOCK_LINE"
    } >> "$ZSHRC"
    echo "Added SSH_AUTH_SOCK to $ZSHRC"
fi

# Create or update ~/.ssh/config with AddKeysToAgent at the top for global scope
SSH_CONFIG="$HOME/.ssh/config"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ ! -f "$SSH_CONFIG" ]; then
    echo "AddKeysToAgent yes" > "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
    echo "Created $SSH_CONFIG with AddKeysToAgent"
elif grep -qE '^AddKeysToAgent\s+yes' "$SSH_CONFIG"; then
    echo "AddKeysToAgent yes already configured in $SSH_CONFIG"
else
    # Remove any existing AddKeysToAgent lines and prepend the correct one
    tmp=$(mktemp)
    grep -v '^AddKeysToAgent' "$SSH_CONFIG" > "$tmp" || true
    echo "AddKeysToAgent yes" | cat - "$tmp" > "$SSH_CONFIG"
    rm "$tmp"
    echo "Added AddKeysToAgent yes at the top of $SSH_CONFIG"
fi

echo ""
echo "Setup complete! Restart your shell or run:"
echo "  export SSH_AUTH_SOCK=\"\$XDG_RUNTIME_DIR/ssh-agent.socket\""
