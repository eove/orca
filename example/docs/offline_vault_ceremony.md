# Using the Offline PKI


Document created from repository [@ORCA@gitremote@](@ORCA@gitremote@) at commit :  
`@ORCA@commit@`

## Verifying this document

Please follow your organisation's way of verifying a document to make sure this document has not been tampered with.
A gpg-based one can be found in [the O.R.CA documentation](https://eove.github.io/orca/unstable/signing_and_verifying.html)

Once this document is verified, for easier copy/paste of commands in this document, we recommend to use a [HTML version of this workflow](https://eove.github.io/orca/unstable/document_generation.html), generated at the above commit.

## Introduction

This document explains how to use the Offline Root CA from preparing the ceremony until a report is signed and shared.
That event is called a *ceremony*.


In case you encounter a term that you do not understand, please refer to [the O.R.CA documentation's glossary](https://eove.github.io/orca/unstable/glossary.html)

## Overview

### Architecture of the vault system

{{#include ./architecture.md}}


### Note on scripts

{{#include ./note-on-scripts.md}}

## Planning a ceremony

This whole chapter has to be done *before* the day of the ceremony.

### Creating a team to work on the vault system

Initially, one person should take care of organising an official ceremony to manipulate the offline vault.
This person is called the `organiser` (📢).

To perform the actual work on the vault system, the organiser will need to gather a team of at least 2 tech-savy people.
These people are called the `team members` (👥), the 📢`organiser` can be one of them.
These people will perform preparative work *before* the ceremony and they will be present *during* the ceremony.

> [!Important]  
> All 👥`team members` should have a hardware token to secure their unseal share. They will need this to both unseal the vault and sign the report.

The 📢`organiser` should communicate to all 👥`team members` the list of operations (and therefore scripts) that will be performed during the ceremony. The aforementionned scripts should be commited to the `actions` directory of this repository prior to the verification phase.

#### Configuring the ceremony

The 📢`organiser` should know which environment will be worked on (`prod`/`preprod`), modify the value of `orca.environment-target` in orca-config.nix accordingly, and notify this environment to all 👥`team members`.

The 📢`organiser` should get the value of the *C<sub>vault</sub>* present in the last report and set the value of `orca.latest_cvault` in orca-config.nix accordingly. If the ceremony is the first one for this environment, then `null` should be set. It is recommended that the 📢`organiser` verifies the validity of the report in the same way the 👥`team members` [will do during the verification phase](#verification-of-the-last-ceremonys-report).

The 📢`organiser` should know what will be done during the ceremony and set the values of `orca.actions_in_order` and `orca.rotate_keys` in orca-config.nix accordingly.

#### Updating the version of the offline vault

The software we are using to run the *ephemeral vault* should not be obsolete (to allow for smooth migration of data, and avoid any unpatched security weakness).

Check if there is any new stable release that is more recent than what is specified in the exploitation repository's flake.nix's `inputs.nixpkgs.url` and `inputs.orca.url` . If so, we should upgrade to the lastest stable release.

Otherwise update the `flake.lock` to the most up-to-date packages by running:
```bash
nix flake update
```

Once changes have been performed, commit the modified files to the [repository](@ORCA@gitremote@).

#### Inserting/checking up-to-date GPG public keys

> [!Warning]  
> This section should only be executed if there was any change in the set of keys in use. In all other cases, please skip to the next section.

The 📢`organiser` asks all `share holders` (including 👥`team members`) to check that the [hardware token](https://eove.github.io/orca/unstable/hardware_tokens.html) they own has its [public key](https://eove.github.io/orca/unstable/gpg_public_key.html) recorded in the env-specific directory located under [`share_holders_keys/`] in the exploitation repository and if it needs to be updated or added, they should do it via a signed commit.

> [!Tip]  
> Github automatically signs commits performed via the online Github web interface.

> [!Tip]  
> The public key can be checked with the corresponding hardware token plugged in and with the public key imported in gpg.\
> For this, enter the following command:\
> `echo "It works" | gpg -e -f /path/to/public/key.pub | gpg -d`

#### Setting up the trusted commit

When all scripts planned for the ceremony are ready and all keys are up-to-date, the 📢`organiser` writes down the last git commit of [the exploitation repository](@ORCA@gitremote@) containing all re-inserted keys, and communicates this commit to all 👥`team members`.

For the rest of this documentation, we are going to name that commit the `trusted commit` (✅)

> [!Important]  
> That commit should not change until the end of the procedure. If it does, for any reason, then you should restart the whole process from the beginning.

### Verification of the offline CAs

> [!Important]  
> While performing verification steps, you should be outside of a `nix develop`. You may need to deactivate your `direnv` for this.

#### Verification of the last ceremony's report

First, we will verify the report of the last ceremony.

> [!Warning]  
> This section should not be executed at the first initialisation of the vault because we have no previous report. In that case, please skip to the next section.

This step *must* be performed by all 👥`team members` *before* the day of the ceremony

Get the last report for the corresponding environment and verify the signatures following your organisation's way of verifying a document.
A gpg-based one can be found in [the O.R.CA documentation](https://eove.github.io/orca/unstable/signing_and_verifying.html)

> [!Warning]  
> All signatures should be valid. The check above should be valid for at least the 3 👥`team members` of the previous ceremony.
>
> Only **one** invalid/missing signature is enough to **stop the ceremony**. In such a case, the issue should be analysed.

Once all signatures has been verified, to get ready for subsequent steps, extract from the `previous ceremony report`:
 - the `trusted commit` that was used back then (that we will refer to as `previous trusted commit`)
 - the checksum *C<sub>vault</sub>* of the previous vault private data that was computed when closing down the ceremony back then.

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
git diff <previous ceremony trusted commit> 
```

> [!Important]  
> * The ceremony's configuration (environment, *C<sub>vault</sub>*, etc…) that [has been set by the 📢`organiser`](#configuring-the-ceremony) should be verified.
> * No custom action script should ask for user input or give an interactive shell.
> * Any change displayed by the diff should be considered legitimate to you.
> * During this step, 👥`team members` will also review and understand all the scripts that are planned for execution during the ceremony.
> * Scripts should never ask the offline topmost root CA to sign anything that doesn't strictly remains in the offline vault (no external CSR).
> * If the offline CA is signing a CSR from a third party (for example online) CA, the authenticity of the CSR file should be checked. Please consult your online PKI documentation to know how to authentify the emitter of the CSR.

Once all 👥`team members` have validated the new ✅`trusted commit`, each of them will gather some fingerprinting data concerning the bootable media that will be used during the ceremony:

Start by building a bootable iso image:
```bash
nix build
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

The bootable live media should be created by one 👥`team member` *before* the day of the ceremony. This person will be the 📝`reporter` during the ceremony.

In order to create a bootable live USB media, we will need a physical USB stick that has a physical write protection switch.

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

> [!Warning]  
> The rest of this section should not be executed at the first initialisation of the vault because we have no previous backup. In that case, please skip to the next section.

Fetch offline CA private data backup for the corresponding environment (eg: prod, preprod etc.).

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

## Executing the ceremony

3 roles *must* be assigned during the execution of the ceremony.\
2 of them will be distributed to already nominated 👥`team members` who all should also have at hand their own copy of the validated ceremony's workflow document.

> [!Important]  
> The `observer` (👀) should be **randomly** picked up. More on this below.

These 3 persons should be **physically present during the whole ceremony**, and **have their hardware token with them**.

1. The first role is the `operator` (💻).\
   This person is the one typing the commands during the verification phase and manipulates the `observer`'s computer.\
   They follow their own copy of this workflow document.

2. The second role is the `reporter` (📝).\
   This person has their own copy of this ceremony workflow document.\
   This person **must** be the person that created the USB stick.\
   During the whole ceremony, this person will fill in the sections framed with a <span style="border:2px dotted dodgerblue;padding-left:2px;padding-right:2px;">dotted-blue border</span>.

> [!Tip]
> To extract these sections from the html version of the ceremony's workflow, use the following filter:\
>  `cat /path/to/ceremory_workflow.html | sed -e 's|<\([/]\)*code class="language-report">|\n<\1\@ORCA\@report\@>\n|g' | sed -n -e '/<\@ORCA\@report\@>/,/<\/\@ORCA\@report\@>/{s/<[/]*\@ORCA\@report\@>//;p}' | sed -e '$a\@GPG\@SIGNATURES\@' | tee /tmp/blank_report.txt`

3. The third role is the `observer` (👀).\
   This person should be [randomly](https://www.random.org/lists/) picked among all share holders except the two other 👥`team members`. The random draw will be performed by either the 💻`operator` or 📝`reporter`.\
   The 👀`observer` will lend their computer to run the *ephemeral vault*. This machine must have a Linux x86_64 OS installed.\
   They must be sitting next to the 💻`operator`. Gets the validated ceremony workflow from the 💻`operator`, and validates that the ceremony is done *exactly* as documented.\
   Make sure that this computer has more than one USB port available:
   * one port to be used for the O.R.CA stick during the whole ceremony.
   * one or more USB port that fits the USB format of the hardware tokens (USB-A, USB-C etc.).

> [!Warning]
> At boot time, and if possible during the whole ceremony, the only hardware that can be used is the hardware of the `observer` (👀).\
> This means that if a USB adaptor, a hub or a external keyboard is necessary, it **must** be hardware owned by the `observer` (👀).\
> If not, you may plug it only **after** the `ephemeral vault` has successfully been booted from the stick.

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
All changes are legitimate .................................. PASS [] / FAIL []

A key rotation will be performed (Yes/No) : ...............

Scripts that will be executed during the maintenance phase (content of `orca.actions_in_order`):
...............................................................................
...............................................................................
...............................................................................
...............................................................................
...............................................................................
...............................................................................

A bootable live media has been generated for this ceremony ........... PASS [] / FAIL []
The team member who brings the bootable media is the reporter: ....... PASS [] / FAIL []

The offline CA private data has been restored from the following archive file:
...............................................................................

```

</td></table>

### Verifying then booting the *ephemeral vault*

The machine of the 👀`observer` will be used during the whole ceremony to verify and boot the *ephemeral vault*. That machine can be any x86_64 PC able to boot on a live media.

> [!Warning]  
> Only the 📝`reporter` is allowed to touch the bootable live media.

> [!Warning]  
> The *ephemeral vault* machine should not be connected to any IP network.  
> All cables attached to the machine should be evaluated, especially USB-C power supplied.

To check the key:
- Before inserting the USB stick, the 📝`reporter` switches the physical button of the stick to *read-only*. The stick *must stay on read-only until it is successfully booted*
- The following steps must be performed without booting on the USB stick, with the USB stick still in *read-only* mode, and directly on the installed Linux OS of the 👀`observer`'s computer.
- An environment variable `Niso` should be set with the correct value, then the key is verified by the 💻`operator` (number of partitions, *N<sub>iso</sub>* checksum):
```bash
sudo fdisk -l /dev/sda &&\
 sudo dd if=/dev/sda bs=512 skip=1 count=$(expr $Niso / 512) |\
 sha256sum -b
```
- the result sha256 should match the value *C<sub>iso</sub>* computed from the ✅`trusted commit`.

> [!Note]  
> The example above assumes `/dev/sda` is the Linux device name for the bootable live media. Please adapt to your setup.

If the checksum *C<sub>iso</sub>* is correct and only the first partition is bootable:
- Power off the 👀`observer`'s computer.
- The 👀`observer`'s computer is rebooted once more on the USB stick.

When booting *ephemeral vault*, a NixOS logo will appear with a boot menu mentionning `O.R.CA xxxx`.

<table width=100% style="border:2px dotted dodgerblue;"><td style="padding:0;">

```report
The key with the vault iso image is set as read only ........ PASS [] / FAIL []

The operator's machine:
can select the key as boot device ........................... PASS [] / FAIL []
can successfully complete boot on the readonly key .......... PASS [] / FAIL []

While performing the USB stick content check on the operator's machine:
the first partition is the only one marked as bootable ............... PASS [] / FAIL []
the checksum *Ciso* is correct ....................................... PASS [] / FAIL []
the computer has been powered off while the USB stick was still read-only .. PASS [] / FAIL []

The key for the ephemeral vault is then set as read/write and the ephemeral ...
vault is immediately booted ................................. PASS [] / FAIL []
```

</td></table>

From now on, the ceremony will run automatically while stopping after each step to let the 👥`team members` time to validate everything is going as planned and fill the report.

A message is printed on the screen indicating the stick can now be switched to *read/write*.

> [!Warning]
> If anything goes wrong, the ceremony will stop and all data except the audit logs and the screen recording will be wiped.

### Checking boot-time verifications

In order to be sure that offline private data has not been tampered with (or downgraded to an old state), at boot, we compute a cryptographically secure checksum on the vault private data *C<sub>vault</sub>*, that should match the *C<sub>vault</sub>* announced in the previous ceremony's report.

After booting, that computed checksum is displayed on the screen, as well as the existing root token count (that should be 0) and the vault status.

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

The vault will be in sealed status.

In order to unseal the vault, you will need to gather enough participants that have an unseal key share to reach the minimum quorum.

On the *ephemeral vault*, insert each `team member`'s hardware tokens one after the other when instructed to.

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

### Maintenance operations on the offline CAs

Each maintenance script (key rotation, csr signature, CA creation, ...) will now be performed.

<table width=100% style="border:2px dotted dodgerblue;"><td style="padding:0;">

```report
All maintenance script have been executed successfully ....... PASS [] / FAIL []
```

</td></table>

## Closing down the ceremony

To close the ceremony, a serie of actions will be performed leading to a safe shutdown of the *ephemeral vault* and a backup of the state of the vault.

### Root token revocation check

First, the vault will be sealed. Then the number of remaining root tokens will be displayed.

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

The ceremony workflow execution will create a tar archive of the data in the `VAULT_WRITABLE` partition.

The value *C<sub>vault</sub>* is displayed on the *ephemeral vault*'s terminal, together with its graphical representation as a QR code. It is a checksum over the vault private data folder.\
All 👥`team members` should keep a copy of this *C<sub>vault</sub>* value. It will be used to verify that the backup was not altered when extracted from the USB stick.

To finish the ceremony, the stick must be switched to *read-only* mode and stay that way **until the end of the ceremony's workflow**.

The *ephemeral vault* will then switch off.

One of the 👥`team members` inserts the USB stick on their own computer.

> [!Tip]  
> The preferred 👥`team member` to do this is the 📝`reporter` because it allows to speed up the process, but this is not mandatory.  
> Indeed, if it is the 📝`reporter`, then as soon as the archive is sent (see the lines below), the report can be completed and signed by the 📝`reporter` asynchronously while the other 👥`team member` perform verifications.

The 👥`team member` that inserted the USB stick, immediately:
1. copies the tar archive from the `VAULT_WRITABLE` partition to the backup destination corresponding to the environment.
2. sends the tar archive from the `VAULT_WRITABLE` partition to all the participants as an attached file via e-mail
3. gets the AIA data in folder `orca/aia/` of the current environment (prod/preprod) from `VAULT_WRITABLE` partition data and makes it available online.

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

In the backup archive, 👥`team members` will also have access to the session recording.\
All sessions are stored in `orca/recordings/ceremony-*.cast`, and can be viewed using:\
`nix develop --command asciinema play /path/to/orca/recordings/ceremony.cast`
The recording should match what the team members experienced from the unsealing of the vault 
to sealing it back.

<table width=100% style="border:2px dotted dodgerblue;"><td style="padding:0;">

```report
The vault private data archive has been safely stored ....... PASS [] / FAIL []
The checksum of the tar file content matches _Cvault_ ....... PASS [] / FAIL []
Value of the full sha256 checksum of the vault private data folder (_Cvault_):
...............................................................................
The recording matches what happened for all team members .... PASS [] / FAIL []
```

</td></table>

### Signing and saving the report

Before signing the report, please verify its content, specifically:
- the value of the ✅`trusted commit`
- the value of the sha256 checksum of the new offline vault private data (C<sub>vault</sub>)
- the validity of the recording
- name the report to contain the date of the ceremony, for example: *ceremony-report-preprod-2025-03-17*

The 📝`reporter`, 💻`operator`, and 👀`observer` will all sign the report by following your organisation's way of signing documents.
A gpg-based one can be found in [the O.R.CA documentation](https://eove.github.io/orca/unstable/signing_and_verifying.html)

All 👥`team members` should now get a copy of the signed report and perform a check of all signatures using [the same process as when checking the last ceremony's report](#verification-of-the-last-ceremonys-report).
