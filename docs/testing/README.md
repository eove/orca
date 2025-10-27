Several testing environment are available to run scripts and simulate the initialisation/maintenance of an offline CA.

# Local testing

## On a dev vault server

This avoids running a virtual machine, and is an ephemeral setup (the vault is run as a local process in dev/debug mode).

For this, you will thus need a local working installation of the vault service on your host. This either requires installing the vault service on your host or an easier way is to use the vault server in the provided `nix develop` shell.

On a dedicated terminal, start a development server:
```bash
vault server -dev
```

All `.sh` scripts (except the vault initialisation) in `templates` should be able to run against that server, in a second terminal, once you set the two following environment variables (associated values are displayed on the server console):
* `VAULT_ADDR`
* `VAULT_TOKEN`, set with the root token string, starting with (`hvs.`)

To double-check that the two above variables are set properly, you can run:
```bash
vault status
```

If a script needs more environment variables, it should tell you.

## In a VM

This allows to keep the state of your vault across reboots and is very close to the *ephemeral vault* setup but skipping the need to create a USB stick. The state (`VAULT_WRITABLE` partition content) is kept in a generated raw ext4 stored in a local file named `orca-testing-disk.raw`.

> [!Tip]  
> You can loop mount this `.raw` image if you need to access or modify files.

> [!Note]  
> Most probably, you will want a `dev` environment while testing in a VM (not a `preprod` or `prod`) so you will have to make sure `orca.environment-target` is set to `dev` in [src/default.nix](../../src/default.nix).

### Starting the iso in a VM

> [!Important]  
> Because with a VM, we are very close to the real offline *ephemeral vault* setup, the orca configuration and actions should reflect what you want to test.

Run with:
```bash
chmod go-rwx testing/root_key
nix run .
```
A virtual machine that will boot on the iso image (that was automatically mounted), and with a small disk will start.

> [!Note]  
> At the end of your testing session, you'll probably want to delete the backup from the disk. To do so, at the root of O.R.CA, run :
>
> ```bash
> ssh root@localhost -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=accept-new" -p 2222 -i testing/root_key rm '/var/lib/vault/orca/*.tar'
> ```

### Simulating a key with a read/write switch

At the very beginning, you have a prompt allowing you to switch the stick to read-write.

You can do in a terminal **on the host machine**, at the root of O.R.CA, with:

```bash
switch-to-readwrite
```

To switch the "key" to readonly use :
```bash
switch-to-readonly
```

### Simulating Yubikeys

> [!Warning]
> This is only available if you are using the `dev` environment-target

While a yubikey should be inserted in real life, in the VM, you can simulate.
When asked to plug a yubikey, in a terminal **on the host machine**, at the root of O.R.CA, run:

```bash
plug-simulated-yubikey <n>
```

where `<n>` is the number (1 to 4) of the yubikey you want to insert.
Then continue in the VM as in real life.
The passphrase for the simulated yubikeys is `test`

### SSH to the VM

> [!Warning]
> This is only available if you are using the `dev` environment-target

A shell from the host can be useful when testing, especially to be able to make copy/paste to and from the VM.

From the root of O.R.CA on your host, you can ssh to the VM with:
```bash
ssh root@localhost -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=accept-new" -p 2222 -i testing/root_key
```
