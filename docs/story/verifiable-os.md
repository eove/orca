# Verifiable Operating System

Another day, another email from future Jules!
Fine, Jules calls for another meeting.

"How can we trust the offline computer's operating system?" Jules asked.

"What do you mean?" Adira asked.

"What if someone having access to it install some malware on it? We don't need to access the root CA for that." Jules replied

"That's a good point" Shuri said, "one probably could install something to steal the shares during an access and thus get access to the root CA."

"Then we need to check the operating system every time or re-install a new one before each access" Leiko said.

"Yes, but we could also easily corrupt the scripts that we are using to achieve the same effect. We'll need to verify them too." Shuri remarked.

"I think we may be able to do all that at once by using a USB stick." Adira said,"We could use [nix and nixOS](https://nixos.org/) to build an iso image of a USB stick and boot from it to use  the root CA. The nix community is doing a pretty good job at making builds reproducible. That means that we will build exactly the same image on any machine if we build from the same sources. So if we agree on which source we start from, then we can easily verify the USB stick and thus the operating system as well as the scripts."

"And we'll do that right before booting from the key so that we are sure nothing got changed since the check." Leiko added.

"That's a great idea!" Jules said, "Let's do that!"

Five years later, the company grew a lot and everything seemed to go as planned.

One afternoon, Shuri entered Jules office and said "Jules, we have a problem. Someone succeeded to steal the root CA."

"What? How? Are you sure?" Jules asked.

"We are sure because we found some corrupted data on our server that were pushed by a certificate signed by an Intermediate CA that was not ours, but that Intermediate CA was still signed by our root CA" she replied.

"That's going to make a lot of damages! Any idea on how they did it?" Jules asked.

"Yes, we checked every computer and mine came out to be faulty. I probably got hacked at a public event." Shuri said.

Jules said nothing, waiting for the rest of the analysis.

"Anyway," Shuri continued, " it seems it comes from the tool we used to validate the USB stick. It is corrupted on my computer. Bad news, we used my computer to validate the USB stick last time. It turns out that the tool actually fakes the verification, pretending everything is legitimate, and in the meantime overwrites the vault with a modified version. Everything seemed normal to us when using it but with the modified vault, secret data like shares and master keys were displayed in clear in the logs. I checked in the last backup and I found the shares."

"Damn! They are good!" Jules said.

"Yep, and we can't fix it!" Shuri said.

"I'll see with Vernes what we can do" Jules concluded.

Jules couldn't remember any of the previous times his future self used the Delorean but he felt like it was becoming a habit...
