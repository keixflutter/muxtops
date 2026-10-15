# muxtops

A minimal native Termux desktop for Android, accessible from a Mac over VNC
through SSH/Tailscale. Openbox manages windows, Tint2 provides a small taskbar,
PCManFM opens files on demand, and aterm provides the terminal.

No proot distribution, compositor, shell replacement or automatic desktop at
login. SSH and Tailscale stay independent. Desktop processes run only while
needed.

## Install on Android

Use Termux from GitHub or F-Droid. Android 13/aarch64 on Redmi Note 11 Pro is
the tested configuration. For this private repository, authenticate the clone
or copy a checkout over SSH.

```sh
pkg install git
git clone https://github.com/keixflutter/muxtops.git
cd muxtops
bash install.sh
```

The installer enables the official Termux X11 repository and installs the
required packages without recommended extras. It refreshes the specific
network/XML libraries needed by old Termux installs. It does not upgrade all
packages. Create a separate VNC password when prompted.

```sh
desktop start
desktop status
desktop stop
desktop log
```

Display `:1`, 1280×720, VNC loopback port 5901. `status` exits 1 when stopped.
Concurrent starts are serialized. Stop cleans up the display, panel, window
manager and session D-Bus. A recycled/stale PID will not signal an unrelated
process. Use `desktop password` while stopped to change VNC credentials.

## Access from this Mac

With Tailscale active and the existing `redmi` SSH alias configured:

```sh
ssh redmi desktop start
ssh -N -o ExitOnForwardFailure=yes -L 15901:127.0.0.1:5901 redmi
```

Keep the tunnel open. In a separate terminal:

```sh
open vnc://127.0.0.1:15901
```

Use any compatible VNC viewer. The tested viewer is noVNC running locally in
Chrome. On the current test Mac it is available at
`http://127.0.0.1:16080/vnc.html?resize=scale` while the local websockify proxy
and SSH tunnel are running. This temporary viewer is not installed on Android.

For a browser viewer on another Mac, download [noVNC](https://github.com/novnc/noVNC)
and run its official helper against the SSH tunnel:

```sh
./utils/novnc_proxy --vnc 127.0.0.1:15901 --listen 127.0.0.1:16080
```

VNC stays on loopback. The connection between Mac and Redmi is encrypted by
SSH over Tailscale; noVNC may label its local WebSocket connection unencrypted.

The Redmi test install has a random VNC password saved with owner-only
permissions. Retrieve it privately:

```sh
ssh redmi cat .config/muxtops/vnc-password.txt
```

## Desktop controls

- Panel: Terminal, Files, running windows, and Jakarta time.
- Right-click empty desktop: application menu.
- Middle-click empty desktop: window list (including minimized windows).
- Super+Enter or Ctrl+Alt+T: terminal.
- Alt+Tab: switch windows; Alt+F4: close; Alt+Space: window menu.
- Titlebar: drag to move, right-drag to resize, double-click to maximize/restore.
- Standard close/minimize/maximize buttons and panel buttons also work.

Defaults live under `config/` in the repo. The installer copies them to
`~/.config/muxtops` only when absent, so reinstalling preserves user settings.
The Openbox theme is installed at `~/.themes/Muxtops`. Edit the installed
`rc.xml`, `menu.xml` or `tint2rc` for customization, then restart the desktop.
Logs and PID state live in `~/.local/state/muxtops`. XDG config/state/cache
locations are respected.

## Verification and limits

Verified on Redmi Note 11 Pro / Android 13:

- Graphical desktop displayed from this Mac in Chrome/noVNC.
- Password authentication, 1280×720 initialization and SSH tunnel.
- Terminal keyboard input, Files/Terminal panel launchers, focus,
  maximize/restore and window rendering.
- Concurrent starts, restart, process cleanup and stale PID protection.
- Idle core processes (Xvnc, Openbox, Tint2, D-Bus): about **71 MiB summed
  RSS / 45 MiB PSS**, with **0% of one CPU core** in a three-second idle sample.
  RSS counts shared pages more than once; PSS apportions them. Applications,
  active rendering and viewers add memory. These are samples, not guarantees.

Run regression checks (the lifecycle check restarts the test desktop):

```sh
# On the Redmi:
bash tests/lifecycle.sh
# On the Mac, with the SSH tunnel and test credentials above:
python3 tests/check_vnc.py
```

Android can stop Termux in the background. There is no boot service or battery
policy modification. Open Termux and run `desktop start` again if Android kills
it. Display `:1` must be free; muxtops does not remove another application's X
locks. Testing does not guarantee the absence of bugs on other versions or
hardware.

## Remove

Stop the desktop, then remove `$PREFIX/bin/desktop`. Remove packages manually
because other Termux tools may share them. User configs, theme and state can
be kept for reinstalling.
