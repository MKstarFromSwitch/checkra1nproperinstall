#!/usr/bin/env bash
set -euo pipefail

# =======================
# Safe Checkra1n Installer
# =======================

# --------- Variables ---------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DESKTOP_FIX_DIR="$HOME/.local/share/applications"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
EXPECTED_HASH="57dac5251df407ad8246ded66422780c135cce984036d769b68701898e6d07b2"
BIN_ARIA2="$SCRIPT_DIR/bin/aria2c"

# --------- Utility Functions ---------
log() { echo "[Log] $*"; }
error_exit() { echo "[Error] $*" >&2; exit 1; }

check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        error_exit "Required command '$1' is not installed."
    fi
}

ensure_not_root() {
    [[ $EUID -ne 0 ]] || error_exit "Do not run as root. Use a normal user with sudo."
}

confirm() {
    read -rp "$1 [type YES to proceed]: " resp
    [[ "$resp" == "YES" ]]
}

verify_sha256() {
    local file="$1"
    local expected="$2"
    local actual
    actual=$(sha256sum "$file" | awk '{print $1}')
    [[ "$actual" == "$expected" ]] || error_exit "SHA256 mismatch! Expected $expected, got $actual."
}

# --------- Desktop Fix ---------
install_desktop_fix() {
    mkdir -p "$DESKTOP_FIX_DIR"
    if [[ -f "$SCRIPT_DIR/checkra1n.desktop" ]]; then
        install -m 644 "$SCRIPT_DIR/checkra1n.desktop" "$DESKTOP_FIX_DIR/"
        log "Desktop fix installed."
    else
        log "Desktop fix not found, skipping."
    fi
}

check_desktop_env() {
    local desktop="${XDG_CURRENT_DESKTOP:-}"
    if [[ "$desktop" != *GNOME* ]] && ! pgrep -x gnome-shell >/dev/null; then
        log "WARNING: The desktop fix only works for GNOME sessions."
    else
        log "GNOME session detected. Desktop fix will work."
    fi
}

# --------- Sanity Checks ---------
sanity_checks() {
    ensure_not_root
    check_command sudo
    check_command wget
    check_command gpg
    check_command tar
    check_command dpkg
    check_command apt-get
    check_command sha256sum

    [[ "$(uname -m)" == "x86_64" ]] || error_exit "checkra1n only supports x86_64 systems."

    [[ -f "$BIN_ARIA2" ]] || error_exit "$BIN_ARIA2 not found."
    chmod +x "$BIN_ARIA2"
}

# --------- Repository Setup ---------
setup_repo() {
    log "Removing old checkra1n installs..."
    sudo apt-get remove --purge -y checkra1n idevicerestore irecovery || true

    log "Deleting old APT repo files..."
    sudo rm -f /etc/apt/sources.list.d/checkra1n.list
    sudo rm -f /usr/share/keyrings/checkra1n.gpg
    sudo apt-get update

    log "Adding checkra1n APT repo..."
    wget -qO- https://assets.checkra.in/debian/archive.key \
        | gpg --dearmor \
        | sudo tee /usr/share/keyrings/checkra1n.gpg >/dev/null

    echo "deb [signed-by=/usr/share/keyrings/checkra1n.gpg] https://assets.checkra.in/debian /" \
        | sudo tee /etc/apt/sources.list.d/checkra1n.list >/dev/null

    sudo apt-get update
}

# --------- Library Installation ---------
install_libraries() {
    log "Copying aria2c to temp dir..."
    cp "$BIN_ARIA2" "$TMP_DIR/"
    cd "$TMP_DIR"
    chmod +x aria2c

    log "Downloading libraries..."
    ./aria2c -o libs.tar.gz https://mkstarfromswitch.github.io/stuff/libs.tar.gz

    log "Verifying download..."
    verify_sha256 libs.tar.gz "$EXPECTED_HASH"

    log "Extracting libraries..."
    tar xf libs.tar.gz

    log "Installing libraries..."
    sudo dpkg -i ./*.deb || true
    sudo apt-get -f install -y
}

# --------- Checkra1n Installation ---------
install_checkra1n() {
    log "Installing checkra1n, idevicerestore, and irecovery..."
    sudo apt-get install -y checkra1n idevicerestore irecovery
}

# --------- Main ---------
main() {
    clear
    log "checkra1n proper installer v1.1"

    sanity_checks
    check_desktop_env
    read -r -n 1 -s -p "Press any key to start installation..."
    echo

    setup_repo
    install_libraries
    install_checkra1n
    install_desktop_fix

    log "Installation complete!"
    echo "If any errors occurred, open an issue:"
    echo "https://github.com/MKstarFromSwitch/checkra1nproperinstall"
}

main