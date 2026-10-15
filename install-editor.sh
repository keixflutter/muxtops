#!/usr/bin/env bash
# Optional native editor; no Linux container and no desktop autostart.
set -euo pipefail
[[ ${PREFIX:-} == /data/data/com.termux/files/usr ]] || { echo 'Run inside Termux.' >&2; exit 1; }
config=${XDG_CONFIG_HOME:-$HOME/.config}/muxtops
[[ -f $config/tint2rc && -f $config/menu.xml ]] || { echo 'Run install.sh first.' >&2; exit 1; }
case ${1:-} in
    --configure-only) ;;
    '')
        new_app=0
        dpkg-query -W -f='${Status}' code-oss 2>/dev/null | grep -q 'install ok installed' || new_app=1
        apt-get install -y --no-install-recommends libc++ libcrypt code-oss
        if [[ $new_app == 1 ]]; then
            state=${XDG_STATE_HOME:-$HOME/.local/state}/muxtops
            mkdir -p "$state"
            printf '%s\n' code-oss >> "$state/installed-packages"
            sort -u "$state/installed-packages" -o "$state/installed-packages"
        fi
        ;;
    *) echo "Usage: bash install-editor.sh [--configure-only]" >&2; exit 2 ;;
esac
code-oss --version
mkdir -p "$config/launchers"
cat > "$config/launchers/editor.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Code - OSS
Exec=code-oss
Icon=$PREFIX/share/pixmaps/com.visualstudio.code.oss.png
Terminal=false
DESKTOP
if ! grep -q '/launchers/editor.desktop' "$config/tint2rc"; then
    printf '\nlauncher_item_app = %s/launchers/editor.desktop\n' "$config" >> "$config/tint2rc"
fi
if ! grep -q 'label="Code - OSS"' "$config/menu.xml"; then
    sed -i '/<menu id="muxtops-menu"/a\    <item label="Code - OSS"><action name="Execute"><command>code-oss</command></action></item>' "$config/menu.xml"
fi
pkill -USR1 -x tint2 2>/dev/null || true
printf '\nCode - OSS installed. Open it from the panel or desktop menu.\n'
