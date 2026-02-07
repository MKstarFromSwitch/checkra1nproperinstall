# checkra1n proper installer

Properly install checkra1n on Linux for 64-bit (not arm64!)

Normally, installing checkra1n gives you errors about dependencies (usually libncurses5).

This tool both removes existing checkra1n installs and any existing checkra1n repo files, installs necessary libs if they aren't installed, and reinstalls checkra1n (idevicerestore and irecovery too!)

# Well, how do I use this?

First, install Git. (Run the command below)
```shell
sudo apt install git
```

Then, run these commands:
```shell
git clone https://github.com/MKstarFromSwitch/checkra1nproperinstall.git
cd checkra1nproperinstall
```

Then, open a terminal and cd into the directory where you cloned the script and run this command: 
```shell
chmod +x ./go.sh
```

Then, run this command:
```shell
./go.sh
```

It should now work.


# Credits
To the checkra1n team for checkra1n and its APT repo

To me for the script

To the developers of the following libraries: libc6, libtinfo5, libncurses5, libreadline7
