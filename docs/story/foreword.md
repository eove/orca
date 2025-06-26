# Foreword

This short story aims to explain why O.R.CA and especially O.R.CA's workflow works the way it works.
If you want the even shorter version of the story, you can go directly to the [afterword section](./afterword.md).

## Prerequisites

Even though we want to make our explainations as accessible as possible, some subjects won't be explained.
We will list theses subjects and give a very short description of what's important about them in our context.
If you want to know more about a subject or do not trust the very short desciption we made about it, please feel free to dig into it before going any futher.
Wikipedia is probably a good place to start.

### Monster-in-the-middle

When communicating with a server, it is highly probable that your data goes through a chain of machines to reach its destination.
It is possible that one of these machines is own by an ill-intended person.
Because of this, any data going from a computer to another is considered public knowledge.

### Asymetric cryptography

Asymetric cryptography allows someone to share publicly a key (the public key) that can be used to cypher data while keeping another key secret (the private key)
Once it has been cyphered, only the person with the private key is able to read the original message.
Another way to use asymmetric cryptography is to sign a clear text message with the private key.
Any one with the public key can then verify the signature.
This is a good tool to avoid monster-in-the-middle attacks.
