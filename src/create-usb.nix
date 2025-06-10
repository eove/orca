{ isoImage, pkgs, ... }:
let
  rootUsbScript = pkgs.writeShellScriptBin "root-iso-to-usb" ''
    set -e
    TARGET_DEVICE="$1"
    function force_unmount(){
      for MOUNTED in $(${pkgs.util-linux}/bin/lsblk -n -o MOUNTPOINTS $TARGET_DEVICE)
      do
        umount $MOUNTED
      done
    }
    force_unmount
    ISO_SIZE=$(wc -c "${isoImage}/iso/${isoImage.isoName}")
    echo "Going to write $ISO_SIZE bytes to the USB stick at $TARGET_DEVICE"
    ${pkgs.util-linux}/bin/wipefs --all --force "$TARGET_DEVICE"
    dd if=${isoImage}/iso/${isoImage.isoName} of="$TARGET_DEVICE" status=progress
    force_unmount
    echo "start=,size=" | ${pkgs.util-linux}/bin/sfdisk -f -a "$TARGET_DEVICE"
    sleep 2
    force_unmount
    ${pkgs.e2fsprogs}/bin/mkfs.ext4 -F -L "VAULT_WRITABLE" ''${TARGET_DEVICE}3
  '';
  usbScript = pkgs.writeShellScriptBin "iso-to-usb" ''
    set -e
    if [ "$#" -ne 1 ]; then
      echo "Usage : $0 /dev/selected_mass_storage" >&2
      echo "with /dev/selected_mass_storage being the raw device (and not a partition) for a USB stick on which to install the vault live image" >&2
      exit -1
    fi
    KEY="$1"
    if [ "$(<''${KEY/dev/sys\/block}/removable)" != "1" ]; then
      echo "Error : $KEY is not removable." >&2
      exit -2
    fi

    sudo ${pkgs.lib.getExe rootUsbScript} $KEY
  '';
in
{
  type = "app";
  program = "${pkgs.lib.getExe usbScript}";
}
