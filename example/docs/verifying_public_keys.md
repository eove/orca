TODO for IN70 

The 📢`organiser` remove every (if any) key contained in `share_management/share_holders_keys/` and commit that.

The 📢`organiser` asks everyone that will have a share to add [their public key](./gpg_public_key.md) via a signed commit and checks that they still have access to their corresponding private key.
This can be done with :
```
echo "It works !" | gpg -e -f path/to/public/key.pub | gpg -d
```

> [!Tip]  
> For people not signing their commits automatically, Github signs commit done via the online interface.

Once all participants have re-inserted in `share_management/share_holders_keys/`, the 📢`organiser` writes down the last git commit containing all re-inserted keys.

For the rest of this documentation, we are going to name that commit the `trusted commit` (✅)

The 📢`organiser` now verifies that there are at least 5 keys and share the ✅`trusted commit` hash with the 👥`team members`.

> [!Important]  
> That commit should not change until the end of the procedure.
> If it does, for any valid reason, then you should start over the process from here.

All 👥`team members` should do the following verification steps on the ✅`trusted commit` and communicate their result to the other 👥`team members`.
 - Each key should be committed by their owner
 - That commit (that inserted the key) should be signed by their owner

> [!Tip]  
> To check that a commit is signed, the simplest way to do it is to check on Github that the commit is marked as `verified`.
