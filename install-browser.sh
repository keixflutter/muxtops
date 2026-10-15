#!/usr/bin/env bash
# Optional full-featured browser. It is not started with the desktop.
set -euo pipefail
[[ ${PREFIX:-} == /data/data/com.termux/files/usr ]] || { echo 'Run inside Termux.' >&2; exit 1; }
config=${XDG_CONFIG_HOME:-$HOME/.config}/muxtops
[[ -f $config/tint2rc && -f $config/menu.xml ]] || { echo 'Run install.sh first.' >&2; exit 1; }
# Older Termux C++ runtimes cannot load the current Firefox/FFmpeg builds.
apt-get install -y --no-install-recommends libc++ firefox
firefox --version
mkdir -p "$config/launchers"
cat > "$config/launchers/browser.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Firefox
Exec=firefox
Icon=firefox
Terminal=false
DESKTOP
if ! grep -q '/launchers/browser.desktop' "$config/tint2rc"; then
    printf '\nlauncher_item_app = %s/launchers/browser.desktop\n' "$config" >> "$config/tint2rc"
fi
if ! grep -q 'label="Firefox"' "$config/menu.xml"; then
    sed -i '/<menu id="muxtops-menu"/a\    <item label="Firefox"><action name="Execute"><command>firefox</command></action></item>' "$config/menu.xml"
fi
# Tint2 reloads its config in place, preserving the supervised process.
pkill -USR1 -x tint2 2>/dev/null || true
printf '\nFirefox installed. Open it from the panel or desktop menu.\n'
