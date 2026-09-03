# Contributing

Pull requests are welcome, particularly anything that makes the install more robust or adds a useful processing mode.

A few requests:

- Keep `install.sh` idempotent. Running it twice should be safe.
- Run `bash -n` on shell changes and `python3 -m py_compile` on Python changes before opening a PR.
- If you change `scripts/patch_tc001.py`, run it against a fresh upstream clone to confirm it still finds everything it expects.
- Say what you tested on: Pi model, OS release, camera, goggles.
- Please don't commit recordings, screenshots from the camera, logs, or anything device-specific like SSH keys or Wi-Fi credentials.
