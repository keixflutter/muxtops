#!/usr/bin/env bash
# Validates the public installer's plan/validation paths; never installs packages.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
run() { bash "$root/install.sh" --plan "$@"; }
reject() {
    if run "$@" >/dev/null 2>&1; then printf 'Unexpectedly accepted: %s\n' "$*" >&2; exit 1; fi
}
full=$(run --profile full --access phone)
[[ $full == *'127.0.0.1:5901'* && $full == *'firefox code-oss'* ]]
minimal=$(run --profile minimal --access phone)
[[ $minimal != *firefox* && $minimal != *code-oss* ]]
run --access lan --address 192.168.1.50 >/dev/null
run --access lan --address 10.0.0.50 >/dev/null
run --access lan --address 172.16.0.50 >/dev/null
run --access tailscale --address 100.90.80.70 >/dev/null
reject --profile unknown
reject --access nowhere
reject --access tailscale --address 192.168.1.50
reject --access tailscale --address 100.128.0.1
reject --access tailscale --address 100.63.0.1
reject --access lan --address 8.8.8.8
reject --access lan --address 0.0.0.0
reject --access lan --address 192.168.1.999
reject --access lan --address not-an-ip
reject --access lan
reject --address
reject --unknown
printf 'Installer profiles, network choices and invalid inputs: PASS\n'
