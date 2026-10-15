#!/usr/bin/env bash
# Shared validation, no side effects when sourced.
validate_address() {
    local mode=$1 value=$2 a b c d extra part
    IFS=. read -r a b c d extra <<< "$value"
    [[ -z ${extra:-} ]] || { echo 'Invalid IPv4 address' >&2; return 1; }
    for part in "${a:-}" "${b:-}" "${c:-}" "${d:-}"; do
        [[ $part =~ ^[0-9]{1,3}$ ]] && ((10#$part <= 255)) || {
            echo 'Enter four IPv4 numbers between 0 and 255.' >&2; return 1;
        }
    done
    VALIDATED_ADDRESS="$((10#$a)).$((10#$b)).$((10#$c)).$((10#$d))"
    case $mode in
        phone) [[ $VALIDATED_ADDRESS == 127.0.0.1 ]] || { echo 'Phone mode uses 127.0.0.1.' >&2; return 1; } ;;
        tailscale)
            [[ $a == 100 ]] && ((10#$b >= 64 && 10#$b <= 127)) || {
                echo 'Use the 100.64.0.0/10 IPv4 address shown by Tailscale.' >&2; return 1;
            } ;;
        lan)
            [[ $a == 10 || ( $a == 192 && $b == 168 ) ]] || { [[ $a == 172 ]] && ((10#$b >= 16 && 10#$b <= 31)); } || {
                echo 'Use a private Wi-Fi IPv4 address (10.x, 172.16-31.x or 192.168.x).' >&2; return 1;
            } ;;
        keep)
            # Existing settings can only retain the same supported local/private scopes.
            validate_address phone "$value" 2>/dev/null || validate_address lan "$value" 2>/dev/null ||
                validate_address tailscale "$value" || return 1 ;;
        *) echo 'Choose phone, lan or tailscale.' >&2; return 1 ;;
    esac
}
