#!/usr/bin/env bash
# Exercise access changes/rollback and uninstall scope with fake services/filesystem commands.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d)
real_rm=$(command -v rm)
export TEST_REAL_RM="$real_rm"
trap '"$real_rm" -rf "$work"' EXIT
export XDG_CONFIG_HOME="$work/config" XDG_STATE_HOME="$work/state"
export PREFIX=/data/data/com.termux/files/usr
export TEST_EVENTS="$work/events" TEST_RUNNING="$work/running"
mkdir -p "$work/bin" "$XDG_CONFIG_HOME/muxtops" "$XDG_STATE_HOME/muxtops"
cat > "$work/bin/desktop" <<'MOCK'
#!/usr/bin/env bash
case $1 in
    status) test -f "$TEST_RUNNING" ;;
    stop) printf 'stop\n' >> "$TEST_EVENTS"; "$TEST_REAL_RM" -f "$TEST_RUNNING" ;;
    start)
        address=$(cat "$XDG_CONFIG_HOME/muxtops/vnc-address")
        printf 'start %s\n' "$address" >> "$TEST_EVENTS"
        [[ $address != 100.90.80.71 ]] || exit 1
        touch "$TEST_RUNNING" ;;
    *) exit 2 ;;
esac
MOCK
# These stubs record removal requests; they never remove real files or packages.
cat > "$work/bin/rm" <<'MOCK'
#!/usr/bin/env bash
printf 'rm %s\n' "$*" >> "$TEST_EVENTS"
MOCK
cat > "$work/bin/apt-get" <<'MOCK'
#!/usr/bin/env bash
printf 'apt %s\n' "$*" >> "$TEST_EVENTS"
MOCK
chmod +x "$work/bin/"*
export PATH="$work/bin:$PATH"
printf 'fixture-password\n' > "$XDG_CONFIG_HOME/muxtops/passwd"
printf '192.168.1.50\n' > "$XDG_CONFIG_HOME/muxtops/vnc-address"
bash "$root/scripts/configure.sh" --yes --access phone >/dev/null
[[ $(cat "$XDG_CONFIG_HOME/muxtops/vnc-address") == 127.0.0.1 ]]
[[ ! -f $TEST_RUNNING ]]
touch "$TEST_RUNNING"
if bash "$root/scripts/configure.sh" --yes --access tailscale --address 100.90.80.71 >/dev/null 2>&1; then
    echo 'Simulated bind failure unexpectedly succeeded' >&2; exit 1
fi
[[ $(cat "$XDG_CONFIG_HOME/muxtops/vnc-address") == 127.0.0.1 && -f $TEST_RUNNING ]]
bash "$root/scripts/configure.sh" --yes --access tailscale --address 100.90.80.70 >/dev/null
[[ $(cat "$XDG_CONFIG_HOME/muxtops/vnc-address") == 100.90.80.70 && -f $TEST_RUNNING ]]
[[ $(cat "$XDG_CONFIG_HOME/muxtops/passwd") == fixture-password ]]
bash "$root/scripts/configure.sh" --plan --access phone >/dev/null
[[ $(cat "$XDG_CONFIG_HOME/muxtops/vnc-address") == 100.90.80.70 ]]
: > "$TEST_EVENTS"
bash "$root/scripts/uninstall.sh" --yes >/dev/null
! grep -q '^apt ' "$TEST_EVENTS"
! grep -q "$XDG_CONFIG_HOME" "$TEST_EVENTS"
! grep -q "$XDG_STATE_HOME" "$TEST_EVENTS"
grep -q 'libexec/muxtops' "$TEST_EVENTS"
printf 'firefox\ncode-oss\n' > "$XDG_STATE_HOME/muxtops/installed-packages"
: > "$TEST_EVENTS"
bash "$root/scripts/uninstall.sh" --yes --remove-packages --purge-config >/dev/null
grep -q '^apt remove firefox code-oss$' "$TEST_EVENTS"
grep -q "$XDG_CONFIG_HOME" "$TEST_EVENTS"
printf '%s\n' '--invalid-apt-option' > "$XDG_STATE_HOME/muxtops/installed-packages"
if bash "$root/scripts/uninstall.sh" --yes --remove-packages >/dev/null 2>&1; then
    echo 'Invalid package manifest accepted' >&2; exit 1
fi
printf 'Reconfigure, rollback, password preservation and uninstall scope: PASS\n'
