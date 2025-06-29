# Afterword

## TL;DR

In this section, we'll make a summary of the most important points of the O.R.CA workflow, in the order of the workflow. We will link to the story's chapters when relevent.

It worth remainding that [we want to protect ourself against an internal, ill-intent, knowledgeable administrator](./raise-the-bar.md).

### Verifying the workflow document

The workflow document is the starting point for using O.R.CA. If the document is wrong, then the security of the root CA is at risk. See the end of chapter [one factor of authentication is not enough](./mfa.md) for an exemple of an attack on it and chapter [Is this for real?](./story/verify-workflow.md) for more explainations.

### Using Shamir's Secret Sharing

This is used to make sure that nobody can do anything alone.
See chapter [Never alone](./never-alone.md)

### Choosing a trusted commit

This is required to know from which sources to start to reproduce the operating system that will be used to manipulate the offline root CA. This is evoked in chapter [Verifiable Operating System](./story/verifiable-os.md)

### Verifying the previous report

This is required in order to trust the value that will be used to verify the backup that will be used. It is also useful to avoid reviewing the whole operating system and to just verify the changes between the current trusted commit and the last trusted commit.
See chapters [Is this for real?](./story/verify-workflow.md) and [Verifiable Operating System](./story/verifiable-os.md)

### Building the iso on more than one computers

This is useful in order to be confident about the value to use to verify the USB key. Sharing in between the team also makes it a fool-proof step.
See chapter [Verifiable Operating System](./story/verifiable-os.md)

### Choosing the computer to use randomly

The goal is to make prepared attacks less probable to succeed. It's also a nice way to get an observer for the ceremony.
See chapters [All USB keys are not created equals](./story/readonly-usb.md) and [Never alone](./story/never-alone.md)

### Using a USB key with a readonly switch

The goal is to avoid any modification of the key while it's beeing verified. This is also a fool-proof tool in case the operating system that is about to make the verification decides to write anything on it.
See chapter [All USB keys are not created equals](./story/readonly-usb.md)

### Verifying the states after boot

The main goal is to verify that the vault's database has not been tempered. It's also a way to verify that we are indeed at the state described in the previous report.
See chapter [Verifiable Operating System](./story/verifiable-os.md)

### Using hardware tokens

Hardware token can generate a private key directly on it. This mean that the private key can never be seen by any computer, including at creation time. That's a good way to make sure there is no duplicate that could decrypt a share.
Further more, having a hardware token give use first factor of authentication and the pin gives a second one. That's a good way to ensure strong authentication.
See chapter [One factor of authentication is not enough](./story/mfa.md)

### Creating backups

The root CA is the starting point of the security of the whole PKI. It must not be lost, whatever happens.
See chapter [Need backup!](./story/need-backup.md)

### Creating a report and signing it

This is the necessary step to make the next ceremony easier and secure.
See previous section about verifying the previous report
See chapters [Is this for real?](./story/verify-workflow.md) and [Verifiable Operating System](./story/verifiable-os.md)

## Known limitation

O.R.CA is not protected against a USB key that would show one version of the OS at verification time and another version, corrupted, at boot time. It is concidered too sophisticated to do for a single person.

O.R.CA is not protected against social engineering. The people having shares should be aware and trained against this kind of attacks.


