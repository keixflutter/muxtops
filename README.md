# muxtops

**A lightweight desktop inside Android. Install it in Termux, then use it on
that same phone or connect from another device with a VNC viewer.**

Switch between your Android apps and the desktop without rebooting. This is
not dual boot: muxtops runs inside Termux and shares Android's resources.
No root, Linux container, or replacement Android system is needed.

## What you get

| Included | Purpose |
| --- | --- |
| Openbox | Window manager with a minimal dark theme |
| Tint2 | Panel with launchers, window buttons, and a clock |
| PCManFM | File manager |
| aterm | Terminal |
| TigerVNC | View and control the desktop |
| Firefox | Browser, included in the full profile |
| Code - OSS | Native code editor, included in the full profile |

The **full** profile bundles the apps and configuration shown above. Choose
**minimal** to skip Firefox and Code - OSS. Apps only run when you open them.
Code - OSS is the open-source VS Code build provided by Termux, not VSCodium.

## 1. Prepare your phone

- Install **[Termux](https://github.com/termux/termux-app#installation)** from
  GitHub or F-Droid, then open it.
- Have internet access for the initial package downloads. For the full
  profile, allow several GB of free space; package sizes change over time.
- To view the desktop on the phone itself, install **[AVNC from F-Droid](https://f-droid.org/packages/com.gaurav.avnc/)**.
  Another VNC viewer that supports password authentication can also be used.

Tested on **Android 13, arm64**. Package availability and Android background
process limits vary by device. The installer uses official Termux packages.

## 2. Install

Paste these commands into **Termux**:

```sh
pkg update
pkg install git
git clone https://github.com/keixflutter/muxtops.git
cd muxtops
bash install.sh
```

The guided installer asks you to choose:

1. **Apps:** full (desktop + Firefox + Code - OSS) or minimal.
2. **Access:** this phone, same Wi-Fi, or Tailscale.
3. **VNC password:** create your own password. Traditional VNC uses the first
   eight characters; use 6–8 characters. A view-only password is optional.

Keep Termux open until installation finishes. The first download may take a
while. If a download fails, fix the connection and run `bash install.sh` again.
Existing settings and VNC passwords are preserved.

## 3. Start and use it

### On this same phone

Choose **“On this phone”** during installation. Then run:

```sh
desktop view
```

This starts the desktop and opens its `vnc://` address in your Android VNC
viewer. If Android asks which app to use, select AVNC.

If your viewer needs a manually created connection, enter:

| Field | Value |
| --- | --- |
| Name | Anything you like, e.g. My desktop |
| Server / address | `127.0.0.1` |
| Port | `5901` |
| Password | The VNC password you created |

Rotate the phone to landscape. Switch apps to return to Android, and keep
Termux running in the background. No network or Tailscale is required for
this mode after installation. A Bluetooth keyboard/mouse can make work easier.

### From another device on the same Wi-Fi

Choose **“Same private Wi-Fi”** and enter your phone's IPv4 address. Find it
in **Android Settings → Wi-Fi → your connected network → network details**.

Run `desktop start`, then open a VNC viewer on your other device. Use the
phone's Wi-Fi address, port **5901**, and your VNC password. Both devices must
be on the same private network. The phone can also connect to that same address.

This mode uses standard VNC password authentication, which does not encrypt
the desktop traffic. Use it on a trusted private network.

### From another network with Tailscale

1. Install [Tailscale](https://tailscale.com/download) on the phone and your
   other device. Sign in to the same private Tailscale network and connect both.
2. Choose **“Tailscale”** in the installer. Enter the phone's **100.x.x.x IPv4
   address shown in Tailscale**, not its Wi-Fi address.
3. Run `desktop start`.
4. In a VNC viewer, use that Tailscale IP (or its MagicDNS hostname), port
   **5901**, and your VNC password.

No SSH tunnel is needed. Tailscale encrypts the connection between devices.
Keep Tailscale enabled. The phone can also use AVNC with its own Tailscale IP.

**Forgot which address you chose?** Run:

```sh
desktop info
```

## Everyday commands

| Command | What it does |
| --- | --- |
| `desktop view` | Start and open the desktop in an Android VNC viewer |
| `desktop start` | Start the desktop without opening a viewer |
| `desktop stop` | Stop the desktop and its session services |
| `desktop status` | Check whether it is running |
| `desktop info` | Show the VNC address and port |
| `desktop log` | Show recent diagnostic messages |
| `desktop configure` | Change phone, Wi-Fi or Tailscale access without reinstalling |
| `desktop uninstall` | Guided removal; keep settings/packages by default |
| `desktop password` | Change your VNC password while the desktop is stopped |

Closing a viewer disconnects that viewer. It does **not** stop the desktop.
Use `desktop stop` when finished to free its memory. SSH setup is optional
and is not installed or changed by muxtops.

## Change your choices later

Run the guided access switcher:

```sh
desktop configure
```

Choose phone, Wi-Fi or Tailscale access and enter the phone's IP when asked.
No packages are reinstalled and your VNC password stays the same. If the
desktop is running, save your work: the tool asks before restarting it.
If the new address fails to start, it restores the previous address.

For example, to return to same-phone mode:

```sh
desktop configure --access phone
```

To change the app profile, open `~/muxtops` and rerun `bash install.sh`.
The minimal profile does not uninstall apps you already installed. To restore
the bundled appearance, run `bash install.sh --reset-config`; your previous
configuration is backed up and the VNC password is retained.

Optional app installers are also available:

```sh
bash install-browser.sh
bash install-editor.sh
```

## Installer options

The guided installer is recommended for beginners. For repeatable installs:

```sh
# Full desktop for use on the same phone:
bash install.sh --yes --profile full --access phone

# Minimal desktop on private Wi-Fi (replace with this phone's actual IP):
bash install.sh --yes --profile minimal --access lan --address 192.168.1.50

# Tailscale access (replace with this phone's actual Tailscale IP):
bash install.sh --yes --profile full --access tailscale --address 100.90.80.70

# Preview packages and choices without installing anything:
bash install.sh --plan --profile full --access phone
```

`--yes` skips the choice prompts; a fresh VNC password still requires an
interactive terminal. `--help` lists all options. On a reinstall, an omitted
access mode preserves the existing address. Only one explicit interface is
bound; the installer does not listen on every network interface.

## Controls and customization

- Panel buttons open Terminal, Files, and the full-profile apps.
- Click a taskbar button to switch to or minimize its window.
- Right-click empty desktop for the application menu.
- Middle-click empty desktop for a list of windows, including minimized ones.
- Ctrl+Alt+T or Super+Enter opens a terminal. Alt+Tab switches windows.
- Alt+F4 closes a window. Double-click its title bar to maximize/restore.

Personal settings live in `~/.config/muxtops`, the theme in
`~/.themes/Muxtops`, and logs/state in `~/.local/state/muxtops`. XDG config,
state and cache locations are respected. The panel clock uses your environment's
timezone. Edit the installed settings, then stop/start the desktop to reload.

## Troubleshooting

**The viewer cannot connect**

Run `desktop status`, `desktop info`, and `desktop log` in Termux. The viewer's
address and port must match `desktop info`. `127.0.0.1` means the device running
the viewer itself, so use that only when the viewer is on the phone running
muxtops. For remote access, check Wi-Fi/Tailscale and the selected phone IP.
Some guest Wi-Fi networks block connections between devices.

**The IP changed or Tailscale was off when starting**

Enable the selected network first. If the phone's IP changed, rerun the installer
to select its new IP, then start the desktop again.

**Android stopped Termux in the background**

Open Termux again and run `desktop view` or `desktop start`. Android may kill
background processes; optional battery optimization settings differ by vendor.
muxtops does not change these settings or install a boot service.

**Display `:1` is occupied**

Another X/VNC server may be running. Stop that session or stop your existing
muxtops session first. muxtops does not delete other applications' X locks.

**An app is slow**

Close unused browser tabs/apps. The minimal desktop has no compositor or
animation service. A base idle test measured about **45 MiB PSS / 71 MiB
summed RSS** for the desktop services on the tested phone. Open apps need
additional memory; these measurements are not a performance guarantee.

## Development checks

`bash tests/installer.sh` checks installer choices and rejects invalid inputs
without changing the machine. `bash tests/management.sh` tests reconfiguration,
rollback and uninstall behavior with mocked services/removal commands. `bash tests/lifecycle.sh` is an on-device
integration test that **restarts the desktop**, so save work before running it.
`python3 tests/check_vnc.py --help` describes the VNC authentication check.

## Uninstall

```sh
desktop uninstall
```

The tool shows its plan and asks for confirmation. By default it stops the
desktop and removes the muxtops commands, **keeping your password, settings,
theme and installed packages** for a later reinstall.

Optional cleanup:

```sh
# Also delete muxtops settings, password, theme and logs:
desktop uninstall --purge-config

# Also ask apt to remove packages recorded as introduced by muxtops:
desktop uninstall --remove-packages

# Show the plan without making changes:
desktop uninstall --plan
```

Package cleanup never uses `autoremove`, and does not target packages that
were already installed before muxtops. Review apt's removal proposal: other
apps may now depend on some of those packages. `--yes` skips only muxtops's
confirmation; apt still asks before removing packages. The cloned project
folder is kept. To reinstall, run `bash install.sh` from it.

## License

muxtops scripts and original configuration/assets are MIT-licensed. Installed
apps and libraries retain their own licenses. AVNC and Tailscale are separate
Android apps and are not bundled as APKs in this repository.
