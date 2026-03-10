Gemini said
🛡️ Yubikey GPG & SSH Provisioning
This repository serves as a universal "bootstrap" for setting up a secure workstation in seconds. It allows me to move between machines (CachyOS/Arch, macOS, or Debian) and immediately have my SSH authentication and GPG signing environment ready using a Yubikey as the hardware root of trust.

📁 Repository Structure
yubi-setup.sh: A universal Bash script that detects the OS, installs dependencies, configures the GPG-to-SSH bridge, and handles Fish shell integration.

public_key.asc: My GPG public key. (The script is designed to prefer fetching this directly from the URL stored on the Yubikey hardware, but this serves as a fallback).

🚀 One-Liner Setup
On a brand-new machine, plug in the Yubikey and run the following command. It is idempotent, meaning it can be safely re-run to verify or repair a configuration.

Bash
curl -sL https://raw.githubusercontent.com/april/april/main/yubi-setup.sh | bash
What the script automates:
Dependency Management: Detects the OS and installs gnupg, pcscd, and the appropriate pinentry (QT, Mac, or GTK).

Hardware Bridge: Enables and starts the pcscd daemon required for smart card communication.

SSH Integration: Configures gpg-agent to handle SSH requests and injects the SSH_AUTH_SOCK into ~/.config/fish/config.fish.

Zero-Touch Import:

Reads the public key URL stored on the Yubikey metadata.

Imports the key and automatically grants it "Ultimate Trust".

Restarts the agent to apply all changes immediately.

🔑 Post-Setup Usage
1. SSH Authentication
The Yubikey is now your SSH agent. To use it with GitHub or remote servers:

Export Public String: gpg --export-ssh-key apriljwarren@proton.me

Test Connection: ssh -T git@github.com (Touch the gold contact when the Yubikey flashes).

2. GPG Verified Commits
This environment is pre-configured to support cryptographic signing. To enable the "Verified" badge for your Git commits:

Code snippet
git config --global user.signingkey <YOUR_KEY_ID>
git config --global commit.gpgsign true
⚠️ Troubleshooting
"Card not available": If GPG cannot see the key, restart the hardware daemon:

Linux: sudo systemctl restart pcscd

macOS: brew services restart pcscd

Fish Agent: If ssh-add -l is empty, ensure you have restarted your terminal or run source ~/.config/fish/config.fish.

Permissions: If GPG complains about unsafe permissions, run chmod 700 ~/.gnupg.


