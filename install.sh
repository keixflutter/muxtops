#!/usr/bin/env bash
set -euo pipefail

if [[ ${PREFIX:-} != /data/data/com.termux/files/usr ]]; then
    echo 'Run this installer inside Termux.' >&2
    exit 1
fi
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# Install only the desktop essentials. Do not upgrade unrelated packages.
pkg install -y x11-repo
apt-get install -y --no-install-recommends tigervnc openbox aterm dbus libexpat libcurl libssh2 libnghttp2 feh xorg-xrdb xorg-xprop tint2 pcmanfm
# Atomic replacement keeps a running supervisor on its original script inode.
launcher=$(mktemp "$PREFIX/bin/.muxtops-desktop.XXXXXX")
trap 'rm -f "$launcher"' EXIT
install -m755 "$repo_dir/bin/desktop" "$launcher"
mv -f "$launcher" "$PREFIX/bin/desktop"
config=${XDG_CONFIG_HOME:-$HOME/.config}/muxtops
mkdir -p "$config"
# Preserve user settings on reinstalls; defaults are copied only when absent.
for name in rc.xml menu.xml tint2rc wallpaper; do
    [[ -f $config/$name ]] || install -m644 "$repo_dir/config/$name" "$config/$name"
done
for folder in launchers icons; do
    mkdir -p "$config/$folder"
    for source in "$repo_dir/config/$folder/"*; do
        target="$config/$folder/$(basename "$source")"
        [[ -f $target ]] || install -m644 "$source" "$target"
    done
done
mkdir -p "$HOME/.themes/Muxtops/openbox-3"
install -m644 "$repo_dir/config/theme/themerc" "$HOME/.themes/Muxtops/openbox-3/themerc"
# Substitute default templates without altering customized files.
escaped=$(printf '%s' "$config" | sed 's/[&|\\]/\\&/g')
xml_path=$(printf '%s' "$config/menu.xml" | sed 's/\&/\&amp;/g; s/[&|\\]/\\&/g')
sed -i "s|MU XTOPS MENU PATH|$xml_path|g" "$config/rc.xml"
for target in "$config/tint2rc" "$config/launchers/terminal.desktop" "$config/launchers/files.desktop"; do
    sed -i "s|MU XTOPS CONFIG PATH|$escaped|g" "$target"
done
if [[ ! -s $config/passwd ]]; then
    echo 'Create a VNC password (separate from SSH):'
    vncpasswd "$config/passwd"
fi
chmod 600 "$config/passwd"
printf '\nInstalled. Run: desktop start\n'
