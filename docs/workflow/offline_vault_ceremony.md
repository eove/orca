# Using the Offline PKI


Document created from repository [@ORCA@gitremote@](@ORCA@gitremote@) at commit :  
`@ORCA@commit@`

## Verifying this document

Please follow your organisation's way of verifing a document to make sure this document has not been tempered with.
A hand made one can be found at the [signing and verifying annex](../signing_and_verifying.md)

## Introduction

This document explains how to use the Offline Root CA from preparing the ceremony until a report is signed and shared.
That event is called a *ceremony*.

All commands are given for Linux using a bash shell. Please adapt acording to your environment.

{{#include ./common/glossary.md}}

## Overview

### Architecture of the vault system

{{#include ../architecture.md}}

### Secret sharing system

{{#include ../secret_sharing.md}}

### Note on scripts

{{#include ../note-on-scripts.md}}

## Planning a ceremony

This whole chapter has to be done *before* the day of the ceremony.

### Creating a team to work on the vault system

{{#include ./creating_a_team.md}}

> [!Important]  
> All 👥`team members` should have a hardware token (Yubikey) that secures their unseal share. They will need this to both unseal the vault and sign the report.

The 📢`organiser` should communicate to all 👥`team members` the list of operations (and therefore scripts) that will be performed during the ceremony. The aforementionned scripts should be commited to the `src/scripts/` directory of this repository prior to the verification phase.

#### Selecting the vault environment

The 📢`organiser` should know which environment will be worked on (`prod`/`preprod`), modify the value of `orca.environment-target` in [src/default.nix](../../src/default.nix) accordingly, and notify this environment to all 👥`team members`.

#### Updating the version of the offline vault

The software we are using to run the *ephemeral vault* should not be obsolete (to allow for smooth migration of data, and avoid any unpatched security weakness).

Check if there is any new stable release that is more recent than what is specified in [src/flake.nix](../../../src/flake.nix)'s `inputs.nixpkgs.url`. If so, we should try to upgrade to the lastest stable release.

Try to update the `flake.lock` to the most up-to-date packages by running:
```bash
cd src/
nix flake update
```

Once changes have been performed, commit the modified files to the [O.R.CA repository](@ORCA@gitremote@).

#### Inserting/checking up-to-date GPG public keys

> [!Warning]  
> This section should only be executed if there was any change in the set of keys in use. In all other cases, please skip to the next section.

The 📢`organiser` asks all `share holders` (including 👥`team members`) to check that the hardware token they own has its public key recorded in the env-specific directory located under [`src/share_holders_keys/`] in this repository and if it needs to be updated or added, they should do it via a signed commit.

> [!Tip]  
> Github automatically signs commits performed via the online Github web interface.

> [!Tip]  
> The public key can be checked with the corresponding hardware token plugged in and with the public key imported in gpg.\
> For this, enter the following command:\
> `echo "It works" | gpg -e -f /path/to/public/key.pub | gpg -d`

#### Setting up the trusted commit

When all scripts planned for the ceremony are ready and all keys are up-to-date, the 📢`organiser` writes down the last git commit of repo [O.R.CA]@ORCA@gitremote@) containing all re-inserted keys, and communicates this commit to all 👥`team members`.

For the rest of this documentation, we are going to name that commit the `trusted commit` (✅)

> [!Important]  
> That commit should not change until the end of the procedure. If it does, for any valid reason, then you should restart the whole process from the beginning.

### Verification of the offline CAs

> [!Important]  
> While performing verification steps, you should be outside of a `nix develop`. You may need to deactivate your `direnv` for this.

#### Verification of the last ceremony's report

First, we will verify the report of the last ceremony.

> [!Warning]  
> This section should not be executed at the first initialisation of the vault because we have no previous report. In that case, please skip to the next section.

This step *must* be performed by all 👥`team members` *before* the day of the ceremony

{{#include ../offline/verifying_last_ceremony_report.md}}

#### Verifying bootable live media related changes

This step *must* be performed by all 👥`team members` *before* the day of the ceremony

> [!Warning]  
> At the first initialisation of the vault, the `previous ceremony trusted commit` mentionned below is unknown, so instead we will take the commit at which this workflow document was generated (`@ORCA@commit@`).

Before doing anything with the new ✅`trusted commit`, we need to verify all potential changes done to the offline vault since the last `previous ceremony trusted commit`.

To do so, checkout the current ✅`trusted commit`:
```bash
git checkout <trusted commit>
```
Then:
```bash
git diff <previous ceremony trusted commit> src/
```

> [!Important]  
> All content within `src/` should only reference files also within `src/`.\
> Any change displayed by the diff should be considered legitimate to you.\
> During this step, 👥`team members` will also review and understand all the scripts that are planned for execution during the ceremony.
> Scripts should never ask the offline topmost root CA to sign anything that doesn't strictly remains in the offline vault (no external CSR).
> If the offline CA is signing a CSR from a third party (for example online) CA, the authenticity of the CSR file should be checked. Please consult your online PKI documentation to know how to authentify the emitter of the CSR.

Once all 👥`team members` have validated the new ✅`trusted commit`, each of them will gather some fingerprinting data concerning the bootable media that will be used during the ceremony:

Start by building a bootable iso image:
```bash
nix build src/.#iso-offline
```

Compute the size of the verifiable bytes (total size - 512) that we will call *N<sub>iso</sub>*:
```bash
export Niso=$(expr $(stat --format=%s -L result/iso/orca-*.iso) - 512) &&\
 echo "Niso=$Niso"
```

Compute a sha256 checksum *C<sub>iso</sub>* of the verifiable bytes:
```bash
export ISO_FILENAME=$(command ls result/iso/orca-*.iso | head -n 1)
dd status=none if=${ISO_FILENAME} bs=512 skip=1 |\
 sha256sum -b | sed -E 's/^([[:xdigit:]]*).*$/Ciso=\1/'
```

Communicate the values of *N<sub>iso</sub>* and *C<sub>iso</sub>* to the other 👥`team members`.

#### Creation of a bootable live media for the vault

The bootable live media should be created by one 👥`team member` *before* the day of the ceremony. This person will be referred to as the `key owner`.

{{#include ../offline/creating_a_usb_stick.md}}

> [!Warning]  
> The rest of this section should not be executed at the first initialisation of the vault because we have no previous backup. In that case, please skip to the next section.

Fetch offline CA private data backup for the correspond environment.

{{#include ../offline/loading_backup.md}}

## Executing the ceremony

3 roles *must* be assigned during the execution of the ceremony.\
2 of them will be distributed to already nominated 👥`team members` who all should also have at hand their own copy of the validated ceremony's workflow document.

> [!Important]  
> The `observer` (👀) should be **randomly** picked up. More on this below.

These 3 persons should be **physically present during the whole ceremony**, and **have their hardware token with them**.

1. The first role is the `operator` (💻).\
   This person is typing commands on a terminal on the *ephemeral vault*, following their own copy of this workflow document and the list of scripts that have been planned to be executed.

2. The second role is the `reporter` (📝).\
   This person has their own copy of this ceremony workflow document.\
   During the whole ceremony, this person will fill in the sections framed with a <span style="border:2px dotted dodgerblue;padding-left:2px;padding-right:2px;">dotted-blue border</span>.\
   To extract these sections from the html version of the ceremony's workflow, use the following filter:\
   `cat /path/to/ceremory_workflow.html | sed -e 's|<\([/]\)*code class="language-report">|\n<\1\@ORCA\@report\@>\n|g' | sed -n -e '/<\@ORCA\@report\@>/,/<\/\@ORCA\@report\@>/{s/<[/]*\@ORCA\@report\@>//;p}' | sed -e '$a\@GPG\@SIGNATURES\@' | tee /tmp/blank_report.txt`

3. The third role is the `observer` (👀).\
   This person should be [randomly](https://www.random.org/lists/) picked among all share holders except the two other 👥`team members`. The random draw will be performed by either the 💻`operator` or 📝`reporter`.\
   The 👀`observer` will lend their computer to run the *ephemeral vault*. This machine must have a Linux x86_64 OS installed.\
   They must be sitting next to the 💻`operator`. Gets the validated ceremony workflow from the 💻`operator`, and validates that the ceremony is done *exactly* as documented.\
   Make sure that this computer has more than one USB port available:\
   * one without adapter nor hub. This port will be used for the removable media during the whole ceremony.\
   * one or more USB port that fits the USB format of the Yubikeys (USB-A, USB-C etc.).

For the rest of the procedure below, you can consider references to 👥`team members` as a synonym for the group of the 3 roles above.

> [!Important]  
> In the report below, and only when initializing the vault the first time, a few `FAIL`ed items are expected.\
> They are identified with a star in the report like this `FAIL* []`

<table width=100% style="border:2px dotted dodgerblue;"><td style="padding:0;">

```report
Name of the organiser:
...............................................................................

Revision of the ceremony workflow used:
@ORCA@rev@

Version (commit) of the workflow document:
@ORCA@commit@

Names of the team members that participate to the ceremony:
Operator: .....................................................................
Reporter: .....................................................................
Observer: .....................................................................
These 3 roles are handled by 3 different people ............. PASS [] / FAIL []
These 3 people are located in the same physical room ........ PASS [] / FAIL []

Date of the ceremony:
...............................................................................

Target environment:
.......................................................... preprod [] / prod []
Trusted commit for the new ceremony:
...............................................................................

Date of the previous ceremony:
...............................................................................
Previous trusted commit (as read from the previous ceremony's report):
...............................................................................
Previous backup sha256 checksum (as read from the previous ceremony's report):
...............................................................................

The ceremony's workflow document (valid rev, signatures) have been checked by:
the operator ................................................ PASS [] / FAIL []
the reporter ................................................ PASS [] / FAIL []

The previous ceremony's report signatures have been verified by:
the operator ............................................... PASS [] / FAIL* []
the reporter ............................................... PASS [] / FAIL* []

The verifiable bytes of the iso are (value of *Niso*):
...............................................................................
The sha256 checksum of the *N* verifiable bytes is (value of *Ciso*):
...............................................................................

The review of changes/content of the bootable live media has been performed by:
the operator ................................................ PASS [] / FAIL []
the reporter ................................................ PASS [] / FAIL []
All (possible) changes are legitimate ....................... PASS [] / FAIL []

A bootable live media has been generated for this ceremony .. PASS [] / FAIL []
Identity of the team member who brings the bootable media (the key owner):
............................................. the operator [] / the reporter []

The offline CA private data has been restored from the following archive file:
...............................................................................
```

</td></table>

### Verifying then booting the *ephemeral vault*

The machine of the 👀`observer` will be used during the whole ceremony to verify and boot the *ephemeral vault*. That machine can be any x86_64 PC able to boot on a live media.

> [!Warning]  
> Only the `key owner` is allowed to touch the bootable live media.

> [!Warning]  
> The *ephemeral vault* machine should not be connected to any IP network.  
> All cables attached to the machine should be evaluated, especially USB-C power supplied.

To check the key:
- Before inserting the USB key, `key owner` switches the physical button of the key to *read-only*
- *While switched to read-only*, the 👀`observer`'s computer is booted on the USB key a first time, just to make sure that this machine can boot successfully on the *ephemeral vault*. When booting finishes, an error message will appear indicating that the USB key is *read-only*, this is expected.
- If successful, the 👀`observer`'s machine can be shutdown.
- The following steps must be performed without booting on the USB key, with the USB key still in *read-only* mode, and directly on the installed Linux OS of the 👀`observer`'s computer.
- An environment variable `Niso` should be set with the correct value, then the key is verified by the 👀`observer` (number of partitions, *N<sub>iso</sub>* checksum):
```bash
sudo fdisk -l /dev/sda &&\
 sudo dd if=/dev/sda bs=512 skip=1 count=$(expr $Niso / 512) |\
 sha256sum -b
```
- the result sha256 should match the value *C<sub>iso</sub>* computed from the ✅`trusted commit`.

> [!Note]  
> The example above assumes `/dev/sda` is the Linux device name for the bootable live media. Please adapt to your setup.

If the checksum *C<sub>iso</sub>* is correct:
- Power off the 👀`observer`'s computer.
- The `key owner` switches the physical button of the key to *read/write*.
- The 👀`observer`'s computer is rebooted once more on the USB key.

When booting *ephemeral vault*, a NixOS logo will appear with a boot menu mentionning `O.R.CA xxxx`.

<table width=100% style="border:2px dotted dodgerblue;"><td style="padding:0;">

```report
The key with the vault iso image is set as read only ........ PASS [] / FAIL []

The operator's machine:
can select the key as boot device ........................... PASS [] / FAIL []
can successfully complete boot on the readonly key .......... PASS [] / FAIL []

While performing the USB key content check on the operator's machine:
the first partition is the only one marked as bootable ...... PASS [] / FAIL []
the checksum *Ciso* is correct .............................. PASS [] / FAIL []
the computer has been powered off while the key was still read-only ...........
............................................................. PASS [] / FAIL []

The key for the ephemeral vault is then set as read/write and the ephemeral ...
vault is immediately booted ................................. PASS [] / FAIL []
```

</td></table>

You will have access to a console-only environment.

> [!Note]  
> If you get errors while booting (no shell), make sure your key has been switched to *read/write*.

> [!Tip]  
> All the subsequent commands have to be entered directly on the *ephemeral vault*'s terminal, they are framed with a <span style="border:2px solid red;padding-left:2px;padding-right:2px;">red border</span>

### Checking boot-time verifications

In order to be sure that offline private data has not been tampered with (or downgraded to an old state), at boot, we compute a cryptographically secure checksum on the vault private data *C<sub>vault</sub>*, that should match the *C<sub>vault</sub>* announced in the previous ceremony's report.

Before the very first shell prompt after booting, that computed checksum is displayed on the screen, as well as the existing root token count (that should be 0) and the vault status.

<table width=100% style="border:2px dotted dodgerblue;"><td style="padding:0;">

```report
The vault private data checksum displayed at boot (_Cvault_) matches the ......
previous ceremony's backup sha256 checksum ................. PASS [] / FAIL* []
0 token exists in the vault private data at startup ......... PASS [] / FAIL []
The vault service status returns "Initialized" = true ...... PASS [] / FAIL* []
The vault service status returns "Sealed" = true ............ PASS [] / FAIL []
```

</td></table>

### Unsealing the *ephemeral vault*

> [!Warning]  
> This section should not be executed at the first initialisation of the vault. In that case, please skip to the next section.

{{#include ../offline/unseal.md}}

&nbsp;<br>

<table width=100% style="border:2px dotted dodgerblue;"><td style="padding:0;">

```report
The offline vault has been unsealed ........................ PASS [] / FAIL* []
Share holders that participated to the unseal process:
...............................................................................
...............................................................................
...............................................................................
```

</td></table>

### Maintenance operations on the offline CAs (optional)

> [!Warning]  
> In the maintenance phase, the 👥`team members` should make sure only the planned scripts (that have been reviewed during the preparation phase) are executed.

The 📝`reporter` communicates the list of scripts that will be run to the 👀`observer` (who did not know about the ceremony before).

> [!Important]  
> If during the maintenance operation, something goes wrong, the ceremony will be cancelled and the 👥`team members` must destroy all data from `VAULT_WRITABLE` partition, and a new ceremony will start over again from the backup.

<table width=100% style="border:2px dotted dodgerblue;"><td style="padding:0;">

```report
Scripts executed during the maintenance phase:
...............................................................................
...............................................................................
...............................................................................
...............................................................................
...............................................................................
...............................................................................
Only the scripts initially planned have been executed ....... PASS [] / FAIL []
```

</td></table>

## Closing down the ceremony

To close the ceremony, we will perform a serie of actions leading to a safe shutdown of the *ephemeral vault* and a backup of the state of the vault.

### Root token revocation check

First, we will seal the vault:
<table width=100% style="border:2px solid red;"><td style="padding:0;">

```bash
seal
```

</td></table>

We now need to make sure there is no existing root token anymore, by running the following command on the *ephemeral vault*:
<table width=100% style="border:2px solid red;"><td style="padding:0;">

```bash
count-tokens
```

</td></table>

`0` should be displayed

<table width=100% style="border:2px dotted dodgerblue;"><td style="padding:0;">

```report
The vault has been sealed ................................... PASS [] / FAIL []
0 token exists in the vault private data before backup ...... PASS [] / FAIL []
```

</td></table>

### Backup and offline vault private data checksum

While the *ephemeral vault* is sealed, we have access to the vault private data inside the `VAULT_WRITABLE` partition.

This data needs to be backed-up to retain the last state of the offline vault.

On the *ephemeral vault* terminal, run:
<table width=100% style="border:2px solid red;"><td style="padding:0;">

```bash
backup
```

</td></table>

The script will create a tar archive of the data in the `VAULT_WRITABLE` partition.

The value *C<sub>vault</sub>* is displayed on the *ephemeral vault*'s terminal, together with its graphical representation as a QR code. It is a checksum over the vault private data folder.\
All 👥`team members` should keep a copy of this *C<sub>vault</sub>* value. It will be used to verify that the backup was not altered when extracted from the USB key.

You can now shutdown the vault:
<table width=100% style="border:2px solid red;"><td style="padding:0;">

```bash
poweroff
```

</td></table>

The USB key is then immediately switched to *read-only* mode **until the end of the ceremony's workflow**.
One of the 👥`team members` inserts the USB key on their own computer.

> [!Tip]  
> The preferred 👥`team member` to do this is the 📝`reporter` because it allows to speed up the process, but this is not mandatory.  
> Indeed, if it is the 📝`reporter`, then as soon as the archive is sent (see the lines below), the report can be completed and signed by the 📝`reporter` asynchronously while the other 👥`team member` perform verifications.

The 👥`team member` that inserted the USB key, immediately:
1. copies the tar archive from the `VAULT_WRITABLE` partition to the backup destination corresponding to the environment:
2. sends the tar archive from the `VAULT_WRITABLE` partition to all the participants as an attached file via e-mail
3. gets the AIA data in folder `orca/aia/` of the current environment (prod/preprod) from `VAULT_WRITABLE` partition data and makes it available on the online vault.

> [!Note]  
> We use a tar format here because it allows for deduplication during the enterprise-wide backup process (that includes all Google Drive content)

All 👥`team members` should now:
1. download the attached private data archive from the e-mail they have received
2. download a copy of the private data archive from the drive

On both these archives, they should perform a checksum of this data with the following command:
```bash
export VAULT_BACKUP=/path/to/ORCA_backup.tar
(export TMP_DIR="$(mktemp -d)" &&\
 cd "$TMP_DIR" &&\
 sudo tar --same-owner -xf "$VAULT_BACKUP" -C . &&\
 sudo find . -type f -exec sha256sum -b {} \; | sort -k2 | sha256sum -)
```

The value displayed should match *C<sub>vault</sub>* grabbed from the QR code above.

> [!Tip]  
> In the backup archive, 👥`team members` will also have access to the session recording.\
> All sessions are stored in `orca/recordings/ceremony-*.cast`, and can be viewed using:\
> `nix develop --command asciinema cat /path/to/orca/recordings/ceremony.cast`

<table width=100% style="border:2px dotted dodgerblue;"><td style="padding:0;">

```report
The vault private data archive has been safely stored ....... PASS [] / FAIL []
The checksum of the tar file content matches _Cvault_ ....... PASS [] / FAIL []
Value of the full sha256 checksum of the vault private data folder (_Cvault_):
...............................................................................
```

</td></table>

### Signing and saving the report

Before signing the report, please verify its content, specifically:
- the value of the ✅`trusted commit`
- the value of the sha256 checksum of the new offline vault private data (C<sub>vault</sub>)

The 📝`reporter`, 💻`operator`, and 👀`observer` will all sign the report.\
In sequence, each of them will run the following command and transfer the resulting signed file (which name is displayed on the console) to the next person:
```bash
export REPORT=/path/to/ceremony_report.txt
export GPG_HW_TOKEN_KEY_ID=$(gpg --card-status |\
 sed -n -E -e 's/^[^:]*sign[^:]*:[[:blank:]]*((:?[[:xdigit:]]{4}[[:blank:]]*){10})/\1/pi')
sed -e '/^@GPG@SIGNATURES@$/q' "$REPORT" |\
 gpg --armor --output - -u "$GPG_HW_TOKEN_KEY_ID" --detach-sign > "$REPORT.sig.asc" &&\
 cat "$REPORT" "$REPORT.sig.asc" > "$REPORT".signed &&\
 rm "$REPORT.sig.asc" &&\
 command ls "$REPORT".signed >&2
```
> [!Note]  
> In the shell snippet above, we catch the hardware token public key ID from the signing key ID in the token, and store this inside variable `GPG_HW_TOKEN_KEY_ID`.  
> You might also do it manually (for example using `gpg --card-status` or `gpg --list-keys --fingerprint`) if this sed oneliner doesn't do the job properly

The last 👥`team member` that signs takes the resulting signed report file and:
1. renames it to contain the date of the ceremony, for example: *ceremonie-d-ouverture-de-la-pki-offline-preprod-d-entreprise-2025-03-17.signed.txt*
2. sends it to all the participants as an attached file via e-mail
3. copies it to Google Drive next to the backup

All 👥`team members` should now:
1. download the attached signed report from the e-mail they have received
2. download a copy of the signed report from the drive

On both these files, they should perform a double check of all signatures with the key committed in the env-specific directory located under `share_holders_keys/` in this repository with [the same process as when checking the last ceremony's report](#verification-of-the-last-ceremonys-report).
