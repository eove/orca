The content of the previous offline vault private data should be extracted and put into the `VAULT_WRITABLE` partition.

If the USB stick's partitions have been mounted automatically by your distro, the following will help in finding out the mount point for the `VAULT_WRITABLE` content:
```bash
lsblk -o name,mountpoint,label,size | grep VAULT_WRITABLE
```

If the above fails, then you will have to mount the `VAULT_WRITABLE` partition (manually on the CLI or by opening the volume in your file manager).  
In the examples below, we use `/VAULT_WRITABLE/mount/point` as the mount point.

You can extract the tar archive of the vault private data with:
```bash
sudo tar --same-owner -xvf ORCA_backup.tar -C /VAULT_WRITABLE/mount/point
```

> [!Tip]  
> You can double-check that the data is correct with:  
> `cd /VAULT_WRITABLE/mount/point && sudo find . -type f -exec sha256sum -b {} \; | sort -k2 | sha256sum -`  
> You should get the same checksum as the value *C<sub>vault</sub>* indicated in the `previous report`.
