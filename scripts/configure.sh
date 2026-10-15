#!/usr/bin/env bash
set -euo pipefail
location=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
common="$location/common.sh"
[[ -f $common ]] || common="$location/../lib/common.sh"
source "$common"
config=${XDG_CONFIG_HOME:-$HOME/.config}/muxtops
mode=''
address=''
yes=0
plan=0
while (($#)); do
    case $1 in
        --access|--address)
            [[ $# -ge 2 && $2 != --* ]] || { echo "$1 needs a value" >&2; exit 2; }
            if [[ $1 == --access ]]; then mode=$2; else address=$2; fi
            shift 2 ;;
        --yes) yes=1; shift ;;
        --plan) plan=1; yes=1; shift ;;
        --help|-h)
            echo 'Usage: desktop configure [--access phone|lan|tailscale] [--address IPv4] [--yes] [--plan]'
            exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
done
if [[ -z $mode && $yes == 0 && -t 0 ]]; then
    printf 'Choose access:\n1) This phone\n2) Same private Wi-Fi\n3) Tailscale across networks\n'
    read -r -p 'Choice [1]: ' answer
    case ${answer:-1} in 1) mode=phone ;; 2) mode=lan ;; 3) mode=tailscale ;; *) echo 'Invalid choice' >&2; exit 2 ;; esac
fi
case $mode in
    phone) [[ -z $address || $address == 127.0.0.1 ]] || { echo 'Phone mode uses 127.0.0.1' >&2; exit 2; }; address=127.0.0.1 ;;
    lan|tailscale)
        if [[ -z $address && $yes == 0 && -t 0 ]]; then
            if [[ $mode == tailscale ]]; then echo 'Enable Tailscale first. Use this phone’s 100.x IPv4 shown by the app.';
            else echo 'Use this phone’s private IPv4 from Android Wi-Fi settings. LAN VNC is not encrypted.'; fi
            read -r -p 'Phone IPv4 address: ' address
        fi ;;
    *) echo 'Select --access phone, lan or tailscale (or run interactively).' >&2; exit 2 ;;
esac
validate_address "$mode" "$address"
address=$VALIDATED_ADDRESS
printf 'New VNC address: %s:5901\n' "$address"
[[ $plan == 0 ]] || exit 0
[[ ${PREFIX:-} == /data/data/com.termux/files/usr ]] || { echo 'Run inside Termux.' >&2; exit 1; }
[[ -d $config ]] || { echo 'Install muxtops first.' >&2; exit 1; }
running=0
desktop status >/dev/null 2>&1 && running=1
if [[ $yes == 0 ]]; then
    [[ -t 0 ]] || { echo 'Use --yes for noninteractive configuration.' >&2; exit 1; }
    [[ $running == 0 ]] || echo 'The running desktop will restart. Save your work before continuing.'
    read -r -p 'Apply this access mode? [y/N]: ' answer
    case $answer in y|Y|yes|YES) ;; *) echo 'Cancelled.'; exit 0 ;; esac
fi
old=127.0.0.1
if [[ -s $config/vnc-address ]]; then read -r old < "$config/vnc-address"; fi
if [[ $running == 1 ]]; then desktop stop; fi
printf '%s\n' "$address" > "$config/vnc-address"
if [[ $running == 1 ]]; then
    if ! desktop start; then
        printf '%s\n' "$old" > "$config/vnc-address"
        echo 'The new address did not start. Restored the previous address.' >&2
        desktop start || true
        exit 1
    fi
fi
printf 'Saved. Use %s, port 5901, with the same VNC password.\n' "$address"
[[ $running == 1 ]] || echo 'Run desktop start (or desktop view on this phone) when ready.'
