# Termux Gormes Bootstrap

Use this guide when the operator wants to run a trusted Gormes gateway on the same Android device as Navivox through Termux.

This is not a silent mobile installer. Phase 1 is a user-run Termux bootstrap. Phase 2 can make Navivox assist the handoff, but Android app sandboxing means Navivox cannot silently install Gormes or run arbitrary Termux commands without explicit user action.

## Source-backed Termux facts

- Termux publishes current install guidance from the Termux app repository and site: <https://termux.dev/en/> and <https://github.com/termux/termux-app>.
- Full app and package support is for Android >= 7.
- Prefer Termux from F-Droid or official GitHub Releases. Google Play currently has an experimental Android 11+ branch with missing functionality compared with the stable F-Droid build.
- The Termux app and plugins must come from one signing source; do not mix Termux APK sources, such as installing the main app from F-Droid and a plugin from GitHub.
- Keep Termux packages current before installing new packages: run `pkg upgrade` regularly.

## Phase 1: user-run Termux bootstrap

1. Install Termux on the Android device.
   - Preferred: F-Droid package `com.termux`.
   - Alternative: official Termux GitHub Releases.
   - Avoid mixing APK sources. If changing sources, uninstall existing Termux app and plugin APKs first and restore from a backup only after reinstalling from the same source family.
2. Open Termux and update package metadata and installed packages:

   ```sh
   pkg upgrade
   ```

3. Install the base tools needed to fetch and inspect the Gormes installer:

   ```sh
   pkg install git curl
   ```

4. Grant shared-storage access only if the operator needs to move logs, screenshots, or exported files between Android storage and Termux:

   ```sh
   termux-setup-storage
   ```

5. Download the trusted Gormes installer instead of piping it straight into a shell:

   ```sh
   curl -fsSLO https://github.com/TrebuchetDynamics/gormes-agent/releases/latest/download/install.sh
   ```

6. Inspect the installer before running it:

   ```sh
   less install.sh
   ```

7. Run the installer after review:

   ```sh
   bash install.sh
   ```

8. After Gormes starts, print the Navivox setup values from Termux:

   ```sh
   gormes navivox connect-info
   ```

9. Paste the reachable base URL and token into Navivox only. Never paste pairing tokens into issues, logs, screenshots, chat transcripts, or this repository.

## Phase 2: Navivox-assisted bootstrap

A future Navivox flow can reduce copy-and-paste mistakes, but it must stay explicit and reversible.

Navivox may help by:

- detecting that no trusted gateway is configured;
- showing the Phase 1 Termux checklist inside the setup flow;
- copying the safe command block to the clipboard;
- opening the official Termux download page or this guide;
- warning when a device URL uses `127.0.0.1` incorrectly for a separate host; and
- prompting the operator to paste values from `gormes navivox connect-info` after Termux finishes.

Navivox must not:

- install Termux APKs itself;
- bypass Android package-install prompts;
- run Termux commands silently;
- read private Termux files directly;
- embed pairing tokens in logs or screenshots; or
- assume a Google Play Termux build has the same behavior as F-Droid or official GitHub Releases.

## Android networking notes

- Same device, Gormes inside Termux: Navivox should usually connect to the loopback URL printed by `gormes navivox connect-info`.
- Android emulator to host Gormes: use `http://10.0.2.2:<port>`.
- Physical Android device to separate host Gormes: use the host LAN, VPN, or Tailscale URL printed by `gormes navivox connect-info`.

## Recovery checks

- If `pkg upgrade` or `pkg install git curl` fails, reopen Termux and retry after selecting a working mirror.
- If `bash install.sh` fails, rerun it with verbose installer diagnostics only if the installer supports that mode, and redact paths or tokens before sharing logs.
- If Navivox cannot connect after Gormes starts, rerun `gormes navivox connect-info` and paste fresh values into Navivox only.
