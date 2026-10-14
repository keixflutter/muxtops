# muxtops

A small, native Termux desktop: Openbox, xterm and TigerVNC. No proot,
full Linux distribution, shell replacement, compositor or background desktop
at login. SSH and Tailscale remain independent.

Status: initial prototype. Shell checks pass; installation and graphical
startup on Android have not yet been verified.

## Install on Android

Requires the GitHub/F-Droid version of Termux, Bash and an internet connection.

```sh
pkg install git
git clone https://github.com/keixflutter/muxtops.git
cd muxtops
bash install.sh
```

The installer enables the official Termux X11 repository and installs only
required packages. Set a VNC password when prompted. Existing shell startup
files and SSH configuration are left alone.

```sh
desktop start
desktop status
desktop stop
desktop log
```

The desktop uses display `:1`, resolution 1280×720 and loopback port 5901.
It runs only when started. Close the desktop with `desktop stop` before
changing the VNC password using `desktop password`.

## Connect from a Mac

With the existing `redmi` SSH alias and Tailscale connected:

```sh
ssh -N -L 15901:127.0.0.1:5901 redmi
```

Leave that terminal open. Connect a VNC client to `127.0.0.1:15901`, or try
macOS Screen Sharing:

```sh
open vnc://127.0.0.1:15901
```

Use the VNC password created during installation. The VNC server listens on
loopback only; SSH carries the connection to the Mac.

## Controls and customization

- Super+Enter: terminal.
- Alt+Tab: switch windows.
- Alt+F4: close window.
- Drag a title bar with the left button to move, right button to resize.
- Double-click a title bar to maximize.

An optional wallpaper can be placed at `~/.config/muxtops/wallpaper`.
Openbox configuration is generated at start; edit `bin/desktop` to customize
it. Logs and session PID live in `~/.local/state/muxtops`.

## Limits

Android may stop Termux in the background. There is no boot service or
battery-policy modification. Display `:1` must be free. Performance and RAM
usage have not been measured. A panel and file manager are planned as optional
additions after verifying the minimal desktop.

## Remove launcher

Stop the desktop, then remove `$PREFIX/bin/desktop`. Package removal is
manual, since other Termux applications may share these dependencies. Keep
or delete `~/.config/muxtops` and `~/.local/state/muxtops` as desired.
