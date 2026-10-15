#!/usr/bin/env bash
# muxtops guided installer. Package binaries come from official Termux repos.
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$repo_dir/lib/common.sh"
profile=full
access=''
address=''
yes=0
plan=0
reset=0
profile_set=0
usage() {
    cat <<'HELP'
Usage: bash install.sh [options]
  --profile full|minimal    Full includes Firefox and Code - OSS (default: full)
  --access phone|lan|tailscale
                           This phone, same Wi-Fi, or your private Tailscale network
  --address IPv4           Required for lan/tailscale without the guided prompt
  --yes                    Use the supplied choices without guided prompts
  --plan                   Show choices/packages without changing anything
  --reset-config           Back up and replace desktop appearance/settings
  --help                   Show this help
Existing VNC passwords are preserved. Android viewer apps are installed separately.
HELP
}
fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }
need_value() { [[ $# -ge 2 && -n $2 && $2 != --* ]] || fail "$1 needs a value"; }
while (($#)); do
    case $1 in
        --profile) need_value "$@"; profile=$2; profile_set=1; shift 2 ;;
        --access) need_value "$@"; access=$2; shift 2 ;;
        --address) need_value "$@"; address=$2; shift 2 ;;
        --yes) yes=1; shift ;;
        --plan) plan=1; yes=1; shift ;;
        --reset-config) reset=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) fail "Unknown option: $1 (try --help)" ;;
    esac
done
[[ $profile == full || $profile == minimal ]] || fail 'Profile must be full or minimal'
config=${XDG_CONFIG_HOME:-$HOME/.config}/muxtops
existing=''
if [[ -s $config/vnc-address ]]; then read -r existing < "$config/vnc-address"; fi
if [[ $yes == 0 && -t 0 ]]; then
    printf '\nWelcome to muxtops\nA small desktop inside Android. No root or reboot needed.\n\n'
    if [[ $profile_set == 0 ]]; then
        printf '1) Full: desktop + Firefox + Code - OSS (recommended)\n2) Minimal: desktop, terminal and files only\n'
        read -r -p 'Choose apps [1]: ' answer
        case ${answer:-1} in 1) profile=full ;; 2) profile=minimal ;; *) fail 'Choose 1 or 2' ;; esac
    fi
    if [[ -z $access ]]; then
        printf '\nWhere will you use the desktop?\n1) On this phone (no network or Tailscale needed)\n2) Another device on the same private Wi-Fi\n3) Another device through Tailscale (works across networks)\n'
        if [[ -n $existing ]]; then printf '4) Keep current address: %s\n' "$existing"; default=4; else default=1; fi
        read -r -p "Choose access [$default]: " answer
        case ${answer:-$default} in
            1) access=phone ;; 2) access=lan ;; 3) access=tailscale ;;
            4) [[ -n $existing ]] || fail 'No existing address'; access=keep ;;
            *) fail 'Invalid access choice' ;;
        esac
    fi
fi
if [[ -z $access ]]; then
    if [[ -n $existing ]]; then access=keep; else access=phone; fi
fi
case $access in
    phone) [[ -z $address || $address == 127.0.0.1 ]] || fail 'Phone mode uses 127.0.0.1'; address=127.0.0.1 ;;
    keep) [[ -n $existing && -z $address ]] || fail 'Cannot keep an unspecified address'; address=$existing ;;
    lan|tailscale)
        if [[ -z $address && $yes == 0 && -t 0 ]]; then
            if [[ $access == tailscale ]]; then
                printf '\nInstall Tailscale on both devices, sign in to your private network, and turn it on.\nFind this phone\047s IPv4 address in the Tailscale app (starts with 100.).\n'
            else
                printf '\nFind this phone\047s IPv4 address in Android Settings > Wi-Fi > connected network.\nUse a trusted private Wi-Fi network. Standard VNC itself does not encrypt traffic.\n'
            fi
            read -r -p "This phone's IPv4 address: " address
        fi
        [[ -n $address ]] || fail "--access $access needs --address with this phone's IPv4 address"
        ;;
    *) fail 'Access must be phone, lan or tailscale' ;;
esac
validate_address "$access" "$address"
address=$VALIDATED_ADDRESS
packages=(tigervnc openbox aterm dbus libexpat libcurl libssh2 libnghttp2 feh xorg-xrdb xorg-xprop tint2 pcmanfm)
if [[ $profile == full ]]; then packages+=(libc++ libcrypt firefox code-oss); fi
printf '\nApps: %s\nAccess: %s\nVNC address: %s:5901\n' "$profile" "$access" "$address"
if [[ $plan == 1 ]]; then printf 'Packages: %s\nNo changes made.\n' "${packages[*]}"; exit 0; fi
[[ ${PREFIX:-} == /data/data/com.termux/files/usr ]] || fail 'Run this inside the Termux Android app (see README)'
if [[ $yes == 0 && -t 0 ]]; then
    read -r -p 'Install with these choices? [Y/n]: ' answer
    case $answer in n|N|no|NO) printf 'Cancelled.\n'; exit 0 ;; esac
fi
state=${XDG_STATE_HOME:-$HOME/.local/state}/muxtops
mkdir -p "$state"
new_packages=()
for package in "${packages[@]}"; do
    if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q 'install ok installed'; then new_packages+=("$package"); fi
done
printf '\nInstalling packages. Keep Termux open; the first download may take a while.\n'
pkg install -y x11-repo
apt-get update
apt-get -o Dpkg::Options::=--force-confold install -y --no-install-recommends "${packages[@]}"
launcher=$(mktemp "$PREFIX/bin/.muxtops-desktop.XXXXXX")
trap 'rm -f "$launcher"' EXIT
install -m755 "$repo_dir/bin/desktop" "$launcher"
mv -f "$launcher" "$PREFIX/bin/desktop"
support="$PREFIX/libexec/muxtops"
mkdir -p "$support"
install -m644 "$repo_dir/lib/common.sh" "$support/common.sh"
install -m755 "$repo_dir/scripts/configure.sh" "$support/configure.sh"
install -m755 "$repo_dir/scripts/uninstall.sh" "$support/uninstall.sh"
if ((${#new_packages[@]})); then
    printf '%s\n' "${new_packages[@]}" >> "$state/installed-packages"
    sort -u "$state/installed-packages" -o "$state/installed-packages"
fi
mkdir -p "$config"
if [[ $reset == 1 ]]; then
    backup="$config.backup-$(date +%Y%m%d-%H%M%S)-$$"
    cp -a "$config" "$backup"
    printf 'Previous settings backed up to %s\n' "$backup"
fi
for name in rc.xml menu.xml tint2rc wallpaper; do
    if [[ $reset == 1 || ! -f $config/$name ]]; then install -m644 "$repo_dir/config/$name" "$config/$name"; fi
done
for folder in launchers icons; do
    mkdir -p "$config/$folder"
    for source in "$repo_dir/config/$folder/"*; do
        target="$config/$folder/$(basename "$source")"
        if [[ $reset == 1 || ! -f $target ]]; then install -m644 "$source" "$target"; fi
    done
done
mkdir -p "$HOME/.themes/Muxtops/openbox-3"
install -m644 "$repo_dir/config/theme/themerc" "$HOME/.themes/Muxtops/openbox-3/themerc"
escaped=$(printf '%s' "$config" | sed 's/[&|\\]/\\&/g')
xml_path=$(printf '%s' "$config/menu.xml" | sed 's/&/\&amp;/g; s/[&|\\]/\\&/g')
sed -i "s|MU XTOPS MENU PATH|$xml_path|g" "$config/rc.xml"
for target in "$config/tint2rc" "$config/launchers/terminal.desktop" "$config/launchers/files.desktop"; do
    sed -i "s|MU XTOPS CONFIG PATH|$escaped|g" "$target"
done
# The panel clock follows the Android environment rather than a fixed timezone.
printf '%s\n' "$address" > "$config/vnc-address"
if [[ ! -s $config/passwd ]]; then
    printf '\nCreate a VNC password for the viewer (6-8 characters; traditional VNC uses the first 8).\n'
    [[ -t 0 ]] || fail 'Password setup needs an interactive terminal. Run desktop password, then rerun the installer.'
    vncpasswd "$config/passwd"
fi
chmod 600 "$config/passwd"
if [[ $profile == full ]]; then
    bash "$repo_dir/install-browser.sh" --configure-only
    bash "$repo_dir/install-editor.sh" --configure-only
fi
printf '\nReady!\n1. Run: desktop start\n2. Open a VNC viewer.\n3. Enter server %s, port 5901, and the password you just created.\n' "$address"
if [[ $access == phone ]]; then
    printf 'On this phone, install AVNC from F-Droid: https://f-droid.org/packages/com.gaurav.avnc/\nUse landscape orientation. Switch apps to return to Android; keep Termux running.\n'
else
    printf 'The same address also works in a VNC viewer on this phone.\nFor Tailscale mode, keep Tailscale connected on both devices.\n'
fi
printf 'Stop when finished: desktop stop\nIf the desktop was already running, restart it to apply new settings.\n'
