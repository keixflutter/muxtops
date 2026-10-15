#!/usr/bin/env bash
set -euo pipefail
yes=0
purge=0
remove_packages=0
plan=0
while (($#)); do
    case $1 in
        --yes) yes=1 ;;
        --purge-config) purge=1 ;;
        --remove-packages) remove_packages=1 ;;
        --plan) plan=1; yes=1 ;;
        --help|-h)
            echo 'Usage: desktop uninstall [--yes] [--purge-config] [--remove-packages] [--plan]'
            echo 'Default: stop/remove muxtops commands; keep settings and all packages.'
            exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done
config=${XDG_CONFIG_HOME:-$HOME/.config}/muxtops
state=${XDG_STATE_HOME:-$HOME/.local/state}/muxtops
printf 'Remove muxtops launcher and management commands.\n'
if [[ $purge == 1 ]]; then echo 'Also delete muxtops settings, VNC password, theme, logs and state.';
else echo 'Keep muxtops settings, VNC password, theme and state for reinstalling.'; fi
packages=()
if [[ $remove_packages == 1 && -s $state/installed-packages ]]; then
    while IFS= read -r package || [[ -n $package ]]; do
        [[ -z $package ]] || packages+=("$package")
    done < "$state/installed-packages"
    # Accept only package-name records, never arbitrary apt arguments.
    for package in "${packages[@]}"; do
        [[ $package =~ ^[a-z0-9][a-z0-9+.-]*$ ]] || { echo 'Invalid package manifest.' >&2; exit 1; }
    done
fi
if [[ $remove_packages == 1 ]]; then
    printf 'Packages introduced by muxtops eligible for removal: %s\n' "${packages[*]:-(none recorded)}"
else echo 'Keep all installed packages.'; fi
[[ $plan == 0 ]] || exit 0
[[ ${PREFIX:-} == /data/data/com.termux/files/usr ]] || { echo 'Run inside Termux.' >&2; exit 1; }
if [[ $yes == 0 ]]; then
    [[ -t 0 ]] || { echo 'Use --yes to confirm a noninteractive uninstall.' >&2; exit 1; }
    read -r -p 'Continue with the changes above? [y/N]: ' answer
    case $answer in y|Y|yes|YES) ;; *) echo 'Cancelled.'; exit 0 ;; esac
fi
if command -v desktop >/dev/null; then desktop stop; fi
# No autoremove: dependencies may also serve other Termux applications.
if [[ $remove_packages == 1 && ${#packages[@]} -gt 0 ]]; then apt-get remove "${packages[@]}"; fi
rm -f -- "$PREFIX/bin/desktop"
rm -rf -- "$PREFIX/libexec/muxtops"
if [[ $purge == 1 ]]; then
    rm -rf -- "$config" "$state" "$HOME/.themes/Muxtops"
fi
printf 'muxtops removed. The cloned project folder is kept for reinstalling.\n'
