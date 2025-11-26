# Providing your GPG public key

This section gives instructions on how to export your GPG key in order to communicate it to others.

You can list your current GPG keys using:
```bash
gpg --list-keys --fingerprint
```

The fingerprint can be seen as a sequence of multiple 4 hexadecimal digits values, right under the public key description.

Pick the appropriate one. It (or one if its subkeys) should have encryption capability (denoted by letter `E`).

Let's also write down the username it is assocated to (an hexadecimal value) (it may be necessary to specify that username if you hold more than one GPG key in your keyring)

Now, we can export this key into a file:

```bash
gpg --armor --output /path/to/my/pulic/key.gpg --export your_fingerprint
```

You can send the `.gpg` file exported above to others.
