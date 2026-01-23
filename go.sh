#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# checkra1n proper installer
# This script was patched by ChatGPT, original version made by me.
# -----------------------------

clear
echo "checkra1n proper installer v1.1"
echo "Credits to the checkra1n team for checkra1n and its APT repo."
echo "Credits to the developers of the following libs:"
echo "libtinfo5, libc6, libreadline7, libncurses5"
echo
echo "This script fixes dependency issues, re-adds checkra1n's APT repo,"
echo "and reinstalls checkra1n over any existing installation."
echo

read -r -n 1 -s -p "Press any key to properly install checkra1n..."
echo
echo

# -----------------------------
# Sanity checks
# -----------------------------

echo "[Log] Performing sanity checks..."

if [ "$(uname -m)" != "x86_64" ]; then
  echo "[Error] checkra1n only supports x86_64 systems."
  exit 1
fi

for cmd in sudo wget gpg tar dpkg apt-get; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[Error] Required command '$cmd' is not installed."
    exit 1
  fi
done

if [ ! -x ./bin/aria2c ]; then
  echo "[Error] ./bin/aria2c not found or not executable."
  exit 1
fi

# -----------------------------
# Sudo access
# -----------------------------

echo "[Log] Checking for sudo access..."
echo "Enter your user password when prompted"
sudo -v
echo

# -----------------------------
# Remove existing installs
# -----------------------------

echo "[Log] Removing any existing checkra1n install..."
sudo apt-get remove --purge \
  checkra1n idevicerestore irecovery \
  libtinfo5 libncurses5 libreadline7 \
  --auto-remove -y
echo

# -----------------------------
# Remove old repo + key
# -----------------------------

echo "[Log] Deleting existing APT repo files..."
sudo rm -f /etc/apt/sources.list.d/checkra1n.list
sudo rm -f /usr/share/keyrings/checkra1n.gpg
sudo apt-get update
echo

# -----------------------------
# Add checkra1n repo
# -----------------------------

echo "[Log] Re-adding checkra1n's APT repo..."
wget -qO- https://assets.checkra.in/debian/archive.key \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/checkra1n.gpg >/dev/null

echo "deb [signed-by=/usr/share/keyrings/checkra1n.gpg] https://assets.checkra.in/debian /" \
  | sudo tee /etc/apt/sources.list.d/checkra1n.list >/dev/null

sudo apt-get update
echo

# -----------------------------
# Install legacy libraries
# -----------------------------

echo "[Log] Installing necessary libraries..."

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

cp ./bin/aria2c "$tmpdir/"
cd "$tmpdir"

chmod +x aria2c
./aria2c -o libs.tar.gz https://mkstarfromswitch.github.io/stuff/libs.tar.gz

tar xf libs.tar.gz

sudo dpkg -i libtinfo5.deb
sudo dpkg -i libreadline7.deb
sudo dpkg -i libncurses5.deb
echo

# -----------------------------
# Install checkra1n
# -----------------------------

echo "[Log] Installing checkra1n (also idevicerestore and irecovery)..."
sudo apt-get install checkra1n idevicerestore irecovery -y
echo

# -----------------------------
# Done
# -----------------------------

echo "[Log] Install complete!"
echo "If any errors occurred, open an issue:"
echo "https://github.com/MKstarFromSwitch/checkra1nproperinstall"
exit 0
