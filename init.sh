echo "Starting setup for Hetzner...";

if passwd -S $(whoami) | grep -q " P "; then
    echo "Password is set.";
else
    echo "No password set." >&2
    passwd
fi

echo "Getting disk name...";
PARTIALDISKNAME=$(lsblk -P | grep 'TYPE="disk"' | awk -F'"' '{print $2}');
DISKNAME="/dev/${PARTIALDISKNAME}";
echo "Disk name: ${DISKNAME}";

echo "Partitioning disk...";
parted "${DISKNAME}" -- mklabel gpt;
parted "${DISKNAME}" -- mkpart root ext4 512MB -8GB;
parted "${DISKNAME}" -- mkpart swap linux-swap -8GB 100%;
parted "${DISKNAME}" -- mkpart ESP fat32 1MB 512MB;
parted "${DISKNAME}" -- set 3 esp on;
echo "Disk partitioned.";

echo "Formatting...";
mkfs.ext4 -L nixos "${DISKNAME}1";
mkswap -L swap "${DISKNAME}2";
swapon "${DISKNAME}2";
mkfs.fat -F 32 -n boot "${DISKNAME}3";
echo "Formatted.";

echo "Installing...";
mount /dev/disk/by-label/nixos /mnt;
mkdir -p /mnt/boot;
mount -o umask=077 /dev/disk/by-label/boot /mnt/boot;
nixos-generate-config --root /mnt;
nixos-install;
echo "Installed.";

echo "Done";
echo "Run reboot for changes to take effect.";
