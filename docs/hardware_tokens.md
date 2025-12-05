# Getting GPG to work with hardware tokens

> [!Warning]  
> There are several families of PIN codes on the hardware token.  
> OpenPGP PIN codes (default user PIN: 123456, default admin PIN: 12345678) are different from PIV PIN codes (PIN, PUK, MGM).  
> In this page, when we use admin/user PIN code, we thus refer to the OpenPGP ones.

If neccessary, install the correct packages. Example for an Ubuntu distro:
```bash
sudo apt install gpg gpg-agent scdaemon pcscd
```

Insert your hardware token.

Quit any possibly running application that could use the hardware token (an authenticator, or a browser).

First, make sure you can communicate with the hardware token:
```bash
gpg --card-status
```
should return details about your hardware token including the serial number. If not, you should first fix communication with the hardware token (missing libs, daemons, configuration etc.) before continuing.

Check that the smart card daemon is running:
```bash
sudo systemctl status pcscd
```

If not, please (re)start it:
```bash
sudo systemctl restart pcscd
pkill gpg-agent
```

If you get an error `gpg: selecting card failed: No such device` and/or `gpg: OpenPGP card not available: No such device`, edit or create a gpg config file in `~/.gnupg/scdaemon.conf` and insert the following content
```
disable-ccid
pcsc-shared
```
([source](https://blog.markushuber.org/2024/09/12/yubikeys-with-gnupg-on-ubuntu-24-04/))

You will probably have to restart `gpg-agent` after editing this file to get gpg working.

```bash
pkill gpg-agent
```

# Generating a new OpenGPG key

If your hardware token is communicating correctly with gpg, the following command should return your hardware token's serial number:
```bash
gpg --card-status
```

```bash
gpg --card-edit
```

Reset the hardware token (see [below](#handling-pin-locks)) if necessary.

Then change the user PIN:
```
passwd
```

And set a new user PIN (by directly typing the old PIN then the new PIN, or if the old PIN is unknown, by typing `admin` first, then selecting option 1 when the option list is displayed)

Switch to admin mode by typing (at the gpg prompt):
```
admin
```

Then change the admin PIN:
```
passwd
```

And set a new admin PIN with option 3.

> [!NOTE]
> The Ed25519/Cv25519 is an example and can be changed as you see fit.
> The contraints are that the algorithm must be supported by
> - the hardware token
> - gnupg
> - hashicorp vault's share encryption (https://developer.hashicorp.com/vault/docs/concepts/pgp-gpg-keybase#initializing-with-gnupg)

Generate a new Ed25519/Cv25519 keyset:

Enter the "card edit" command line tool:
```bash
gpg --card-edit
```

From the card edit prompt, here is a trace of commands & answers to run:
```
admin
key-attr
(2) ECC
(1) Curve 25519
# Enter the admin PIN
(2) ECC
(1) Curve 25519
# Enter the admin PIN
(2) ECC
(1) Curve 25519
# Enter the admin PIN
generate
N
# Enter the user PIN
# Enter the validity (see the recommendations in the periodical check workflow, you can also use the tip below to ease the calculation)
# Enter your identity name `Firstname Lastname`
# Enter your Email address
# Enter a comment, for example `Hardware token`, important when you have multiple GPG keys linked to the same email
# Enter the admin PIN+user PIN as many times as required
quit
```

> [!Note]  
> You will now have an Ed25519 key stored on your hardware token. The private key can never leave the device.  
> A prompt for a passphrase is only required when exporting the private key into a local file, which you should not allow (your response to `Make off-card backup of encryption key?` should be `N`).

> [!Tip]  
> If you want your GPG key to be valid until the 30st December of 2027, for example, the following command will give you the number of days of validity from today:  
> `expr \( $(date --date 'Dec 30 22:00 2027' +%s) - $(date +%s) \) / 3600 / 24`

The long key ID is displayed when exiting gpg. You can retrieve it at a later time using:
```bash
gpg --list-keys
```

# Exporting your OpenGPG public key from your hardware token

Check which gpg key is stored on your hardware token by running:
```bash
gpg --card-status
```

In the last section, you will find the signature key's long ID (multiple 4 digit hexadecimal values separated with spaces), taken from the token internal data.
Because gpg knows about this key, the last digits of the key (short ID) will also be displayed in the `General key info..` section, following a `pub ed25519/` header.

Store the hardware token's GPG key ID in a `GPG_HW_TOKEN_KEY_IDY_ID` environment variable:
```bash
export GPG_HW_TOKEN_KEY_ID=$(gpg --card-status | sed -n -E -e 's/^[^:]*sign[^:]*:[[:blank:]]*((:?[[:xdigit:]]{4}[[:blank:]]*){10})/\1/pi') && echo "$GPG_HW_TOKEN_KEY_ID"
```

To export the corresponding public key, you can execute:
```bash
gpg --export --armor "$GPG_HW_TOKEN_KEY_ID"
```

# Handling PIN locks

> [!Warning]  
> Often, on hardware tokens, there are several domains (PIV, OpenPGP, U2F ...), for encryption/decryption, we use the OpenPGP application.
>


```
gpg --card-status | grep 'PIN.*counter'
```

returns the PIN remaining counts.
An example from a pristine hardware token:
```
PIN retry counter : 3 0 3
                    | | |
                    | | +--- admin PIN attempts remaining (the 24 byte management key (aka MGM))
                    | +----- unused
                    +------- user PIN attempts remaining (up to 8 characters)
```

To force a factory-reset (if you locked the admin PIN):
```
$ gpg --card-edit

gpg/card> admin
gpg/card> factory-reset
```
(or follow https://gist.github.com/dminca/1f8b5d6169c6a6654a95f34a80983218)

To reset the PIN (if you locked the user PIN), this will require to know the admin PIN:
```
$ gpg --card-edit

gpg/card> passwd
gpg: OpenPGP card no. XXXXXXXXXXXXXXXXXX detected

1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit

Your selection? 2
```

# Using your hardware token on a different machine

If your want to use a machine where the keypair was not generated, you must:
* connect your hardware token
* import the exported public key using `gpg --import`
* run `gpg --card-status`

Both your public key and private key are now available for use on this new machine.

# Resources (specific to yubikeys)

> [!Tip]  
> If you didn't save you public key, there are [ways to use your hardware token anyway](https://www.nicksherlock.com/2021/08/recovering-lost-gpg-public-keys-from-your-yubikey/).

* https://github.com/drduh/YubiKey-Guide
* https://whynothugo.nl/journal/2022/07/11/using-a-yubikey-for-gpg/
