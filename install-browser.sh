#!/usr/bin/env bash
# Optional full-featured browser. It is not started with the desktop.
set -euo pipefail
[[ ${PREFIX:-} == /data/data/com.termux/files/usr ]] || { echo 'Run inside Termux.' >&2; exit 1; }
config=${XDG_CONFIG_HOME:-$HOME/.config}/muxtops
[[ -f $config/tint2rc && -f $config/menu.xml ]] || { echo 'Run install.sh first.' >&2; exit 1; }
# Older Termux C++ runtimes cannot load the current Firefox/FFmpeg builds.
case ${1:-} in
    --configure-only) ;;
    '')
        new_app=0
        dpkg-query -W -f='${Status}' firefox 2>/dev/null | grep -q 'install ok installed' || new_app=1
        apt-get install -y --no-install-recommends libc++ firefox
        if [[ $new_app == 1 ]]; then
            state=${XDG_STATE_HOME:-$HOME/.local/state}/muxtops
            mkdir -p "$state"
            printf '%s\n' firefox >> "$state/installed-packages"
            sort -u "$state/installed-packages" -o "$state/installed-packages"
        fi
        ;;
    *) echo "Usage: bash install-browser.sh [--configure-only]" >&2; exit 2 ;;
esac
firefox --version
mkdir -p "$config/launchers"
cat > "$config/launchers/browser.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Firefox
Exec=firefox
Icon=$PREFIX/share/icons/hicolor/48x48/apps/firefox.png
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
