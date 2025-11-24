In order to create a bootable live USB media, we will need a physical USB stick (Kanguru FlashTrust with S/N 2110142010043) that has a physical write protection switch.

> [!Warning]  
> The example below assumes `/dev/sda` is the Linux device name that will be fully erased and where the *ephemeral vault* software is going to be installed, please adapt to your setup.

In order to create this bootable live media, that we will refer to as *ephemeral vault* in the rest of these instructions, we will execute the following command from the root of the vault repository:

> [!Warning]  
> Make sure you are doing this on the ✅`trusted commit`

```bash
nix run . /dev/sda
```

> [!Warning]  
> The content of the device provided as argument will be completely destroyed

By default, this script will create 3 partitions on the *ephemeral vault* media, among which the following are important to us:
* a bootable partition with label `orca-${TARGET_VAULT}` contains the *ephemeral vault* software
* a partition with label `VAULT_WRITABLE` contains the offline CA private data (is mounted on `/var/lib/vault`) when the *ephemeral vault* boots

You can check that with :
```bash
lsblk -o name,label
```
