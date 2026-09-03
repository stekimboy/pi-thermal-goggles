# Security

This is a hobby hardware project, not a hardened system. A few things worth knowing before you run the installer on a Pi you care about.

## What the installer changes

- Enables **console autologin** on `tty1` (`raspi-config nonint do_boot_behaviour B2`) so the display comes up without a keyboard. Anyone with physical access to the Pi and a keyboard therefore gets a shell as that user. This is intended for a dedicated device; don't do it on a Pi that holds anything sensitive.
- Does **not** change SSH configuration. Whatever SSH setup you had remains in place. On a device that leaves the house, use key-based auth and disable password login.
- Runs as root, installs packages with `apt`, clones the upstream repository over HTTPS from GitHub, and edits `config.txt`, `~/.xinitrc`, and `~/.bash_profile`. Backups of the originals are kept and restored by `uninstall.sh`.

## Reporting a problem

If you find an actual vulnerability in the scripts in this repository, open a private vulnerability report through GitHub's security tab rather than a public issue. General "it doesn't work" questions belong in a normal issue.

Please don't paste SSH keys, Wi-Fi passwords, tokens, or full system logs into issues.
