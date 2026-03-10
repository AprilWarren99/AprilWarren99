#!/usr/bin/env bash
set -e

echo "🚀 Starting Yubikey GPG/SSH setup..."

# 1. Detect OS and Install Dependencies
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "💻 OS: macOS detected. Using Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "Error: Homebrew not found. Please install it first."
        exit 1
    fi
    brew install gnupg pinentry-mac pcscd
    PINENTRY_PATH=$(which pinentry-mac)
elif [ -f /etc/arch-release ]; then
    echo "🏔️ OS: Arch/CachyOS detected. Using pacman..."
    sudo pacman -S --needed gnupg pcsc-tools pinentry --noconfirm
    sudo systemctl enable --now pcscd
    PINENTRY_PATH=$(which pinentry-qt 2>/dev/null || which pinentry)
elif [ -f /etc/debian_version ]; then
    echo "🐧 OS: Debian/Ubuntu detected. Using apt..."
    sudo apt update && sudo apt install -y gnupg2 scdaemon pcscd pinentry-gtk2
    sudo systemctl enable --now pcscd
    PINENTRY_PATH=$(which pinentry-gtk-2 2>/dev/null || which pinentry)
else
    echo "⚠️ Unknown OS. Please ensure gnupg and pcscd are installed manually."
fi

# 2. Configure GPG Agent
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg

# Enable SSH support and set pinentry path
grep -q "enable-ssh-support" ~/.gnupg/gpg-agent.conf || echo "enable-ssh-support" >> ~/.gnupg/gpg-agent.conf
if [ ! -z "$PINENTRY_PATH" ]; then
    # Clear existing pinentry-program lines and set the correct one
    sed -i.bak '/pinentry-program/d' ~/.gnupg/gpg-agent.conf 2>/dev/null || true
    echo "pinentry-program $PINENTRY_PATH" >> ~/.gnupg/gpg-agent.conf
fi

# 3. Configure Fish Shell
if [ -d ~/.config/fish ]; then
    echo "🐚 Configuring Fish shell..."
    grep -q "SSH_AUTH_SOCK" ~/.config/fish/config.fish || {
        echo "" >> ~/.config/fish/config.fish
        echo "# Yubikey SSH Integration" >> ~/.config/fish/config.fish
        echo 'set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)' >> ~/.config/fish/config.fish
        echo 'gpgconf --launch gpg-agent' >> ~/.config/fish/config.fish
    }
fi

# 4. Hardware Interaction
echo "🔌 Please plug in your Yubikey..."
until gpg --card-status >/dev/null 2>&1; do 
    sleep 2
    echo "Waiting for card..."
done

# Fetch public key from the URL saved on your Yubikey
echo "📥 Fetching public key from the URL stored on your Yubikey..."
gpg --batch --card-edit --command-fd 0 <<EOF
admin
fetch
quit
EOF

# 5. Automatically Set Ultimate Trust
# We search for the fingerprint of the key associated with your email
FPR=$(gpg --with-colons --list-keys apriljwarren@proton.me 2>/dev/null | awk -F: '/fpr/ {print $10;exit}')

if [ ! -z "$FPR" ]; then
    echo "🛡️ Setting ultimate trust for fingerprint: $FPR"
    echo "$FPR:6:" | gpg --import-ownertrust
else
    echo "❌ Error: Could not find fingerprint. You may need to set trust manually."
fi

# 6. Refresh
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent

echo "✅ Setup Complete!"
echo "Run 'ssh-add -l' in a new terminal to verify your key."
