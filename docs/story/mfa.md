# One factor of authentication is not enough

"What if someone finds a way to infiltrate cameras during a ceremony and steal the shares by recording the whole thing?" Jules said to open the meeting.

"That would… be a problem." Adira replied.

"We need to make sure that the person typing the password is the correct one!" Leiko remarked.

"Then we should use more than one factor of authentication" Shuri said.

"More than one what?" Jules asked.

"Factor of authentication" Shuri replied calmly, "You can authenticate someone in different ways."

"You can do it with something that they know, like a password."

"Or a share, like we currently do for the root CA." Adira added.

"Exactly!" Shuri replied,"You can also ask them to show you something that they have, like their ID card.

And finally, you can verify what they are, like their fingerprint".

"Something they know, something they have and something they are, ok." Jules said.

"Now, the idea of Multi Factor Authentication is to use at least two of these." Shuri continued, "The simplest one would be to have a hardware token. That's a bit like the ID card but for computers. Some even have a fingerprint reader embedded."

"Ok, so we'll buy a hardware token for each one of us, right?" Jules asked.

"Yes, but we'll need to add a layer on top of the Shamir's Secret Sharing used by vault so well need one that can also generate an asymmetric private key on it. We'll use it to encrypt the share." Shuri said.

"[Yubikeys](https://www.yubico.com/products/) can do that!" Leiko said.

"Let's get one for everyone then" Jules said

"And we'll use that oportunity to enable a second factor of authentication everytime it's possible" Adira added.

"Perfect !", Jules said.

"We'll also need to add a step at the verification of the OS to make sure the public keys are legit and indeed do belong to whom they claim to belong.", Leiko said.

"A signed commit should do the trick. Then we'll have to verify the signature.", Shuri said.

"Indeed." Leiko answered.

"Let's do this !" Jules concluded.

Six years later, the company grew quite a lot and a hardware token is given to every new person joining the research and development team.

One evening, Shuri went to Jules home.

"I am sorry Jules, Evil Corp threatened me! I had to do it!" she said.

"Don't worry about what you did, we'll see that later. Are you ok?" Jules asked.

"No, I am not, I betrayed so many of you!" seh said, sobbing.

Jules spent the rest of the night listening to Shuri's trauma and emotions while being conscious that he wasn't even remotely qualified to help her.

Shuri needed to confess the way she stole the root CA. She modified the documentation explaining how to work with the root CA by removing the section about the verification of the USB stick.
She created a corrupted key and asked new recruts to help her access the root CA.

Jules felt rage against Evil Corp. He would go back in time. Again. To save his friends against Evil Corp. Again!

