# Threat model

The goal of O.R.CA is to give a good-enough security of the offline part of the PKI while keeping the cost as low as possible.

The target audience for O.R.CA is small to medium organisations that need to create their own PKI (for IoT purposes for example) but don't have the capacity to handle it like a world-wide root PKI (as Let's encrypt, banks, do, for example).

This means that **O.R.CA is not suited for state-level attacks**.

> [!Warning]  
> If your organisation can financially do more than what O.R.CA offers, you probably should.

The issues that O.R.CA aims to solve are two fold :
 - Mistakes
 - Ill-intent actions


## Mistakes

Working on a high-level CA is stressfull and doing it by hand is error-prone.
O.R.CA aims to reduce stress and mistakes thanks to automation.
Every action made on the offline CAs **must** be automated via a script.
There is no way to do anything meaningfull on the O.R.CA system other than a script.
This is made easy thanks to the fact O.R.CA offers [a way to test these scripts in VMs](https://eove.github.io/orca/v0.6.0/testing). On top of this, we heavily recommend to have a preproduction PKI to validate everything before running it on the production PKI.
If any mistake is detected by O.R.CA or someone during a ceremony, O.R.CA will make sure that no erroneous data can be exploited.

## Ill-intent actions

O.R.CA aims to protect the high-level CAs against **one ill-intent person inside your organisation**.

`Ill-intent` definition here is used loosely. It may be :
- someone that do wants to steal / damage your organisation (the usual definition)
- someone that is threatened (physically or mentally) in order to do something they don't want to do
- someone that is manipulated in order to do something compromising without understanding it
This means that, for our definition, `ill-intent` is not necessarily someone `evil`.

`A person inside your organisation` is anyone that has any privileged access to anything. It goes from the contractor that comes check your offices' heating system to your C-level people.

`one` ill-intent person is set as the goal of O.R.CA (and the limits details below will show that we are not perfectly there yet). As the strech goal, anywhere that limit can be raise, O.R.CA aims to make it configurable.

## Limits of O.R.CA

O.R.CA has known limits (weaknesses) that you should consider before using it.
These limits means **one ill-intent person inside your organisation** could **technically** get control over your offline root CA.
These limits are considered acceptable with regards to the expenses and efforts that would be required to solve them.

### Non dedicated hardware

O.R.CA doesn't ask for a dedicated computer to be used.
This means that anyone that has full control over the computer that will be used for a ceremony could trick other people into thinking that they are using O.R.CA while they are actually using a counterfeit version.

This risk is mitigated by randomly selecting the hardware that will be used during each ceremony. We draw one hardware randomly among as many choices as possible.

### God-like admin

If one person has full admin access to all/most of the hardware among which we draw, then they may deploy their attack everywhere.
This make the randomization ineffective and other mitigations should be considered. Ideally, each hardware that may be selected should have a different administrator. The randomization process actually picks the administrator more than the hardware itself.

## Non-selected but technically better mitigations

Here are some better mitigations with the reason we chose not to keep them.

### The burner

We could buy a new computer for each ceremony. The whole team would go, purchase and unpack it together. That way, we are sure nobody touched it before (a supply chain attack of that scale is considered a state-level attack and is out of the scope of O.R.CA).

This heavily raise the cost of each ceremony, may become an issue for any emergency level ceremony (what if every shop in town is closed?), and is not environment friendly.

### Dedicated hardware

A dedicated computer could be bought and kept **safely**. By safely, we mean that **nobody can single handedly get access to it and nobody can single handedly deny access to it**.

This is the same idea as [secret sharing](./secret_sharing.md), but physically.

A safe with this feature would raise the cost to protect the offline root CA but would be worth it since it solves, for a one time cost, the limits of O.R.CA.

The next chapters form a fiction story to explain some scenarios of attacks and missuses that O.R.CA aims to solve.
You can skip them if you are already convinced that handling a PKI should be done with care and/or you understand the risk scenarios associated with it.
Have a good reading!
