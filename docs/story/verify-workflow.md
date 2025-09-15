# Is this for real?

"What if someone makes a fake workflow and weakens it?" Jules asked.

"As it is for now, we wouldn't detect it" Leiko said.

"We could sign it!" Adira said, "But not by hand, of course, it needs to be verifiable."

"Any digital signature will do" Shuri said, "worst case scenario, we can use the private key inside our hardware token to sign."

"Then, before doing anything that is written, we should verify the signatures." Jules added, "Signatures, plural of course, to avoid the single point of failure."

"I think we should ask the same question about the backup." Adira said

"We need to create a document every time we work on the root CA that will give us as signature of the data we should find in the backup." Leiko said.

"And that document should be signed too." Shuri added.

"And we'll verify the backup at the moment of upload as well as at the moment of use the next time." Adira said.

"And since we have a document, we could make it a full report of what happened." Leiko added.

"That would give us a full audit trail of what happened so that if anything strange happens, we can analyse a lot without actually starting the offline root CA" Adira added.

"And without needing to go back into the past, hide behind the curtains and find out what really occurred..." Jules thought.

"That seems good to me." He concluded.

Six years passed since then. The company grew a lot and Hole-in-one was concidered as success by all counts.

Jules didn't have to go back in time again.

Yet.
