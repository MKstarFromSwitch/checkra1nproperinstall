#!/usr/bin/env -S bash
set -euo pipefail

# Prevent running as root directly
if [[ $EUID -eq 0 ]]; then
  echo "[Error] Do not run this script as root. Use a normal user with sudo."
  exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
desktopfixdir="$HOME/.local/share/applications"
mkdir -p "$desktopfixdir"
export DEBIAN_FRONTEND=noninteractive

clear
desktop_env="${XDG_CURRENT_DESKTOP:-}"

if [[ "$desktop_env" != *GNOME* ]] && ! pgrep -x gnome-shell >/dev/null; then
   echo "WARNING: The desktop fix only works for GNOME sessions."
   echo "You can delete this created file safely if you don't use GNOME:"
   echo "~/.local/share/applications/checkra1n.desktop"
else
   echo "The desktop fix will work for your session."
fi

echo "checkra1n proper installer v1.1"
echo

read -r -n 1 -s -p "Press any key to properly install checkra1n..."
echo -e "\n"

echo "[Log] Performing sanity checks..."

if [ "$(uname -m)" != "x86_64" ]; then
  echo "[Error] checkra1n only supports x86_64 systems."
  exit 1
fi

for cmd in sudo wget gpg tar dpkg apt-get sha256sum; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[Error] Required command '$cmd' is not installed."
    exit 1
  fi
done

if [ ! -f "$script_dir/bin/aria2c" ]; then
  echo "[Error] $script_dir/bin/aria2c not found."
  exit 1
fi

chmod +x "$script_dir/bin/aria2c"

echo "[Log] Checking for sudo access..."
sudo -v
echo

echo "[Log] Removing any existing checkra1n install..."
sudo apt-get remove --purge \
  checkra1n idevicerestore irecovery \
  libtinfo5 libncurses5 libreadline7 \
  --auto-remove -y
echo

echo "[Log] Deleting existing APT repo files..."
sudo rm -f /etc/apt/sources.list.d/checkra1n.list
sudo rm -f /usr/share/keyrings/checkra1n.gpg
sudo apt-get update
echo

echo "[Log] Re-adding checkra1n's APT repo..."
wget -qO- https://assets.checkra.in/debian/archive.key \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/checkra1n.gpg >/dev/null

echo "deb [signed-by=/usr/share/keyrings/checkra1n.gpg] https://assets.checkra.in/debian /" \
  | sudo tee /etc/apt/sources.list.d/checkra1n.list >/dev/null

sudo apt-get update
echo

echo "[Log] Installing necessary libraries..."

tmpdir="$(mktemp -d)"
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

cp "$script_dir/bin/aria2c" "$tmpdir/"
cd "$tmpdir"

chmod +x aria2c
./aria2c -o libs.tar.gz https://mkstarfromswitch.github.io/stuff/libs.tar.gz

# ---------------- SHA256 VERIFICATION ----------------
EXPECTED_HASH="57dac5251df407ad8246ded66422780c135cce984036d769b68701898e6d07b2"

echo "[Log] Verifying download integrity..."
DOWNLOADED_HASH="$(sha256sum libs.tar.gz | awk '{print $1}')"

if [[ "$DOWNLOADED_HASH" != "$EXPECTED_HASH" ]]; then
  echo "[Error] SHA256 mismatch!"
  echo "Expected: $EXPECTED_HASH"
  echo "Got:      $DOWNLOADED_HASH"
  exit 1
fi

echo "[Log] SHA256 verified."
# ----------------------------------------------------

tar xf libs.tar.gz

sudo dpkg -i ./*.deb || true
sudo apt-get -f install -y
echo

echo "[Log] Installing checkra1n (also idevicerestore and irecovery)..."
sudo apt-get install checkra1n idevicerestore irecovery -y
echo

echo "Installing desktop fix..."
install -m 644 "$script_dir/checkra1n.desktop" "$desktopfixdir/"
echo

echo "[Log] Install complete!"
echo "If any errors occurred, open an issue:"
echo "https://github.com/MKstarFromSwitch/checkra1nproperinstall"
exit 0

