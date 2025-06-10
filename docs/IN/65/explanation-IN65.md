# Why so many steps in the IN65

> [!Note]  
> The `VAULT_WRITABLE` does not have to be necessarily on the same physical support as the *ephemeral vault*, it could be on any mass storage accessible to the machine that is booting the *ephemeral vault*
> However, there should be only one partition with this label, so if don't use the *ephemeral vault* media to store the offline CA private data, you should rename or delete the `VAULT_WRITABLE` on that media to avoid confusion.
> The existence of such a partition can be checked with the following command:

## Writting down the commit from the beggining

The goal here is to make sure any subsequent verification cannot be bypassed by committing later.

## check public key
- We need to be sure the owners of the public keys still have their private key.
- We need to be sure the public keys where not tempered.

We want to check the last commit of each keys via their signature.
Github online interface signs commit.
Verifying the keys when verifying the signatures is important because otherwise we could hide an ill-intent commit.

## sha backup
Avoid tempering

## sha usb 
Idem

## Verif signature IN65
Idem

## Clé write-protected physique
Pas de tempering while checking usb key by observer

## Draw operator
Minimize probability of bad operator

## Observers
Validate operator action are valid
Check what is done on the vault machine (need to physical presence)

## Boot on computer that just checked the key
Avoid key switch

## Observer that make the key is different from the one testing it
Avoid too much power in one hands

## ls /vault/sys/token
Because vault always returns a 200 answer so we need to double check no tokens are present at the end.
We check that vault still does this even after an update by checking just after root token generation.


## setup des logs before unseal
The goal is to avoid a hidden token from last time to be reused without anyone noticing

## revoke token
Avoid a token that can be used next time

## Seal / stop service
Avoid files to change after checking it / IN65

## Checksum backup on offline computer
The offline computer is the only one trusted

## Sha logs des observers are equals
Check that no tempering of logs happened

## Read-only when not booting on key
After being built, only the OS on the key is trustworfy to noone can write on it.

## Sign report
Seal the values of the report (git commit and backup's sha)
Must be signed by at least 3 people to avoid the insider attack
