# CTO as a security guard

The next Monday, Jules, Shuri and Adira meet again.

"I gave it some thoughts.", started Jules,"We'll need a intermediate CA too since the production team will have to create certificates every day. Making the root CA accessible easily would be too risky."

"Agree, we'll have an intermediate CA signed by the root CA that will be accessible by the production team. The intermediate CA will expire from time to time and that's the only moments we'll need to have access to the root CA.", said Adira.

"If nothing goes wrong yes", completed Shuri, "We'll need access to the root CA if the intermediate CA is hacked in order to revoke it."

"So, the main question is to protect the root CA.", continued Jules, "I am thinking that I'll keep it on my computer that has it's hard drive encrypted and a strong password. I'll be the only one to know the password to use the private key of the root CA."

"That's a simple way to solve the issue.", answered Shuri.

"But you'll have to make sur your computer is always up-to-date. The whole company security will depend on you and tht computer.", insisted Adira.

"That's my life's project we are talking about, of course I'll be carefull ! And I'll use my password manager to create a secured password and keep it safe", answered Jules.

The team decided to go for that.
The company had a greater success than expected and by the end of year 1 was already selling more than 5000 units a month.

By then end of year 2 though, it seems that some data got corrupted. Shuri's first analysis showed that some devices where connecting with two different certificates. Since certificates are loading in the device only once on the production line, it means that something was off with the PKI.

With the help of Adira, they quickly realised that some of the certificates where created by an unknown CA that somehow got signed by the root CA.

"No way !", said Jules, "I am the only one to have access to the root CA and I certainly did NOT sign any other CA than ours !".

"I understand Jules," said Adira, "and yet here we are. I will need to have access to your computer in order to check it. Of course, you are welcome to stay with me and do it with me."

"Ok, let's do that !", said Jules.

After a few research, they found something suspicius.

"Do you see that process ?", asked Adira, "I think it's a key logger. Basically, it register everything you type and send it somewhere on the internet."

"How did it ended up there ?! I obviously didn't install it !", objected Jules.

"It seems it got install 8 mounth ago. Did anything weird happen 8 mounth ago ?", asked Adira.

"None that I can remember.", answered Jules.

"Can we check your emails at that time ?", asked Adira.

"Sure !", volontired Jules.

Adira look a bit in the emails that arrived around the date they found and quickly asked.

"Do you remember that email ? Did you click on the link ? If so, what happened ?"

"Ho, yes ! That's a failed email. I try to get the document, but after I logged in, nothing happened. I coudn't get the document.", answered Jules.

"That's because it's not legit !", remarked Adira, "I seems it comes from Evil Corp. It's a fishing email. By loggin, you gave them your password. They used it to log in your computer and installed the key logger. Then waited for you to use the root CA which you did 6 month ago to renew the Intermediate CA. At that point they got the password for the root CA and signed they certificate."

"Well, let's revoke their intermediate CA then !", thought Jules.

"Yes, that's a way to stop the bleeding but I am afraid the damages are done.", remarks Adira.

"I don't know. I'll talk to Vernes about it.", concluded Jules.

Half an our later, Jules was meeting with Vernes.

"We found what happened.", started Jules, "We got hacked and found a way to close the door. Everything should go back to normal."

"I don't thing so.", said Vernes, "Our reputation is in a bad shape. Evil Corp's copy of the Hole-in-one is raising and they are flouding social network of post showing the problem. Half of the planned orders got cancelled. I am afraid that's the beginning of the end."

"That bad ugh ?", asked Jules, raising an eyebrow.

"I am afraid so. If I am correct, we'll have to get rid of people in a few months. And even with that, I don't think we'll survive.", answerd Vernes, sad.

"Fine, I'll talk to dad.", said Jules, shame resonnating in his voice.

"Good luck with that.", concluded Vernes, defeated.

That evening, Jules went to see his parents, Emmett and Clara, for dinner.

"Dad, I suppose you hear the news about Hole-in-one ?", he asked.

"Yes we did son. I hope you'll recover.", answered Emmett.

"Of course they will !", said Clara promptly.

"I am afraid not.", said Jules, "Vernes is quite pessimistic about it. He thinks we'll be bankrupt within few mounth."

"Great Scott !", yelled Emmett.

"Dad", started Jules, "I hate to have to ask you that,"

"Say no more !", interupted Emmett, "I knew that day would come".

"And I spent long nights convincing your stubborn father !", added Clara.

"The keys of the Delorean are at the entrance. Go, warn yourself with every details needed to avoid this disater and come back quickly to avoir to disrupt the spacetime continuum too much !", continued Emmett.

"Thanks mom !", Jules said while hugging his father.

Jules went two years back in time, sent himself an email explaining everything and used the delorean again to dissappear back to the futur.
