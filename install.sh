#!/usr/bin/env bash
set -euo pipefail

if [[ ${PREFIX:-} != /data/data/com.termux/files/usr ]]; then
    echo 'Run this installer inside Termux.' >&2
    exit 1
fi
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# Install only the desktop essentials. Do not upgrade unrelated packages.
pkg install -y x11-repo
apt-get install -y --no-install-recommends tigervnc openbox aterm dbus libexpat feh xorg-xrdb
install -Dm755 "$repo_dir/bin/desktop" "$PREFIX/bin/desktop"
mkdir -p "$HOME/.config/muxtops" "$HOME/.local/state/muxtops"
if [[ ! -s $HOME/.config/muxtops/passwd ]]; then
    echo 'Create a VNC password (separate from SSH):'
    vncpasswd "$HOME/.config/muxtops/passwd"
fi
chmod 600 "$HOME/.config/muxtops/passwd"
printf '\nInstalled. Run: desktop start\n'
