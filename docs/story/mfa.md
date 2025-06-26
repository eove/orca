# One factor of authentication is not enough

"What if someone finds a way to infiltrate cameras during a ceremony and steal the shares by recording the whole thing ?", said Jules to open the meeting.

"That would... be a problem.",answered Adira.

"We need to make sure that the person typing the password is the correct one !", remarked Leiko.

"Then we should use more than one factor of authentication", said Shuri.

"More than one what ?", asked Jules.

"Factor of authentication", answered Shuri calmly, "You can authenticate someone in different ways.

You can do it with something that they know, like a password."

"Or a share, like we currently do for the root CA.", added Adira.

"Exactly !", answered Shuri,"You can also ask them to show you something that they have, like their ID card.

And finally, you can verify what they are, like their fingerprint".

"Something they know, something they had and something they are, ok.", said Jules.

"Now, the idea of Multi Factor Authentication is to use at least two of these.", continued Shuri, "The simplest one would be to have a hardware token. That's a bit like the ID card but for computers. Some even have a fingerprint reader embedded."

"Ok, so we'll buy a hardware token for each one of us, right ?", asked Jules.

"Yes, but we'll need to add a layer on top of the Shamir's Secret Sharing used by vault so well need one that can also generate an asymetric private key on it. We'll use it to encrypt the share.", said Shuri.

"[Yubikeys](https://www.yubico.com/products/) can do that !", said Leiko.

"Let's get one for everyone then", said Jules

"And we'll use that oportunity to enable a second factor of authentication everytime it's possible", added Adira.

"Perfect !", concluded Jules.

Six years later, the company grew quite a lot and a hardware token is given to every new person joining the research and development team.

One evening, Shuri went to Jules home.

"I am sorry Jules, Evil Corp threatenned me ! I had to do it !", she said.

"Don't worry about what you did, we'll see that later. Are you ok ?", asked Jules

"No, I am not, I betrayed so many of you !", she said, sobbing.

Jules spent the rest of the night listening to Shuri's trauma and emotions while being conscious that he wasn't even remotely qualified to help her.

Shuri needed to confess the way she stole the root CA. She modified the documentation explaining how to work with the root CA by removing the section about the verification of the USB key.
She created a corrupted key and asked new recruts to help her access the root CA.

Jules felt rare against Evil Corp. He will go back in time. Again. To save his friends against Evil Corp. Again !

