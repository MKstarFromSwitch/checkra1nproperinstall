#!/bin/bash
clear
echo checkra1n proper installer v1.0
echo Credits to the checkra1n team for checkra1n and its APT repo.
echo Credits to the developers of the following libs: libtinfo5, libc6, libreadline7, libncurses5
echo "This only fixes dependency issues but will also re-add checkra1n's APT repo if it exists, and will reinstall over any existing checkra1n install."
echo
read -p "Press any key to properly install checkra1n..." -n1 -s
echo
echo "[Log] Checking for sudo access..."
echo "Enter your user password when prompted"
sudo -v
echo
echo "[Log] Removing any checkra1n install..."
sudo apt-get remove --purge checkra1n idevicerestore irecovery libtinfo5 libncurses5 libreadline7 --auto-remove -y
echo
echo "[Log] Deleting existing APT repo files..."
echo
sudo rm /etc/apt/sources.list.d/checkra1n.list 2>/dev/null
sudo rm /usr/share/keyrings/checkra1n.gpg 2>/dev/null
sudo apt-get update
sudo apt update
echo
echo "[Log] Re-adding checkra1n's APT repo..."
wget -O - https://assets.checkra.in/debian/archive.key | gpg --dearmor | sudo tee /usr/share/keyrings/checkra1n.gpg >/dev/null
echo 'deb [signed-by=/usr/share/keyrings/checkra1n.gpg] https://assets.checkra.in/debian /' | sudo tee /etc/apt/sources.list.d/checkra1n.list
sudo apt-get update
sudo apt update
echo
echo "[Log] Installing necessary libraries..."
rm -rf ./tmp/
mkdir -p ./tmp/
./bin/aria2c -d ./tmp/ -o templibs.tar.gz https://mkstarfromswitch.github.io/stuff/libs.tar.gz
tar xvf ./tmp/templibs.tar.gz -C ./tmp/
rm ./tmp/templibs.tar.gz
sudo dpkg -i ./tmp/libtinfo5.deb
sudo dpkg -i ./tmp/libreadline7.deb
sudo dpkg -i ./tmp/libncurses5.deb
echo
echo "[Log] Installing checkra1n (also idevicerestore and irecovery)..."
sudo apt-get install checkra1n idevicerestore irecovery -y
echo
echo "[Log] Install done! Open an issue in my repo if any error has occured: https://github.com/MKstarFromSwitch/checkra1nproperinstall"
exit

