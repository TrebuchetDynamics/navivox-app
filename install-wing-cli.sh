#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_cli="$script_dir/wing-cli"
source_qr="$script_dir/vendor/qrcodegen.py"
install_dir="${WING_CLI_INSTALL_DIR:-$HOME/.local/bin}"
install_data_dir="${WING_CLI_INSTALL_DATA_DIR:-$HOME/.local/share/wing-cli}"
use_sudo=false

usage() {
  cat <<'EOF'
Usage: ./install-wing-cli.sh [--system | --prefix DIR]

Installs wing-cli for the current user in ~/.local/bin by default.
  --system      Install machine-wide in /usr/local/bin (uses sudo when needed)
  --prefix DIR  Install in a custom directory
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --system) install_dir="/usr/local/bin"; install_data_dir="/usr/local/share/wing-cli"; use_sudo=true; shift ;;
    --prefix) install_dir="${2:?--prefix requires a directory}"; install_data_dir="$install_dir/.wing-cli"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -f "$source_cli" && -f "$source_qr" ]] || {
  echo "wing-cli or its vendored QR encoder was not found beside this installer." >&2
  exit 1
}

install_files() {
  install -D -m 0755 "$source_cli" "$install_dir/wing-cli"
  install -D -m 0644 "$source_qr" "$install_data_dir/qrcodegen.py"
}

if [[ "$use_sudo" == true && $EUID -ne 0 ]]; then
  command -v sudo >/dev/null 2>&1 || {
    echo "sudo is required for --system." >&2
    exit 1
  }
  sudo install -D -m 0755 "$source_cli" "$install_dir/wing-cli"
  sudo install -D -m 0644 "$source_qr" "$install_data_dir/qrcodegen.py"
else
  install_files
fi

"$install_dir/wing-cli" --help >/dev/null
printf 'Installed wing-cli to %s\n' "$install_dir/wing-cli"
if [[ ":$PATH:" != *":$install_dir:"* ]]; then
  printf 'Add %s to PATH to run wing-cli from any directory.\n' "$install_dir"
fi
printf 'Installed vendored QR encoder to %s\n' "$install_data_dir/qrcodegen.py"
