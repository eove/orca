# Is this for real ?

"What if someone makes a fake workflow and weakens it ?", asked Jules.

"As it is for now, we wouldn't detect it", said Leiko.

"We could sign it !", said Adira, "But not by hand, of course, it needs to be verifiable."

"Any digital signature will do", said Shuri, "worst case scenario, we can use the private key inside our hardware token to sign."

"Then, before doing anything that is written, we should verify the signatures.", added Jules, "Signatures, plural of course, to avoid the single point of failure."

"I think we should ask the same question about the backup.", said Adira

"We need to create a document every time we work on the root CA that will give us as signature of the data we should find in the backup.", said Leiko.

"And that document should be signed too.", added Shuri.

"And we'll verify the backup at the moment of upload as well as at the moment of use the next time.", said Adira.

"And since we have a document, we could make it a full report of what happenned.", added Leiko.

"That would give us a full audit trail of what happenned so that if anything strange happens, we can analyse a lot without actually starting the offline root CA", added Adira

"That seems good to me.", concluded Jules.

Six years passed since then. The company grow a lot and Hole-in-one was concidered as success by all counts.

Jules didn't have to go back in time again.

Yet.
