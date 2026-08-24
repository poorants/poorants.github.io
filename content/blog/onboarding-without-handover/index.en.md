+++
title = "I Skipped the Handover"
date = 2026-08-25T00:00:00+09:00
draft = false
tags = ["agentic-workflow", "platform-engineering", "onboarding", "ai-transformation", "developer-experience"]
+++

When someone new joined the team, I gave them no handover. I did not sit them down and walk through the shape of our systems, and I did not tell them what to install first. I handed over a link to an onboarding page, and that was all.

Not long after, their development environment was standing. Credentials were in place, the internal services were connected, and they were running the team's working workflow as it is. Except that the person did not perform that setup. They handed the onboarding page to an AI agent, said 'set this up as written', and the agent executed it from beginning to end.

This was by design, not by accident. But intending something and understanding what it means are two different things. The page took half a year to arrive at, and only after that half year did it become clear what I had actually built. I thought I had written a guide for people. What I had finished was a procedure an agent executes.

## The friction called handover

For a long time, a handover meant moving knowledge from one person's head into another's. You replicate a map of the system in someone else's mind, then confirm through conversation that the copy is good enough. Success was usually measured in time. How quickly did they understand it?

The cost of this approach lands on the person handing over. Time spent explaining, time spent answering the same question again, and the time that comes back later as an incident because something went unexplained. That cost repeats in full every time a person joins. Writing documents does not reduce it, because documents always trail reality, and only the people who know that fail to trust them.

The problem I wanted to solve was not how to write better documents. It was whether the handover step could be removed altogether.

## Friction summons the thing that removes it

Looking back, nothing built over that half year came from a plan. Each thing emerged where the previous one hurt.

The first was a screen showing builds and deployments, because moving artifacts between servers by hand was the bottleneck. Next came a dashboard gathering issues and tasks, because the team was not looking at the same screen to see what had slipped. Then came a unified gateway, because every tool carried its own credentials and each new tool meant copying the same secret one more time.

Once the gateway stood, the next gap appeared. Work the agents did was flowing away without a trace, so team records and retrospectives followed. Product knowledge lived only in people's heads, so a documentation pipeline followed. And last came the onboarding bootstrap, because all of it had to be handed to someone else.

The first five took half a year. The last one took a day. That asymmetry leads to the first conclusion.

## The direction was always to shrink the surface

More important than the list is the direction. Every decision pointed the same way: not adding tools, but shrinking the surface.

Five internal services — the wiki, the issue tracker, the file server, the code host, and the product operations target — moved behind a single gateway. I did not build a separate command-line tool alongside it, so there remained exactly one place to call. Credentials went the same way. What had been scattered was collected into one file in the user's home directory, and the consumers stopped reading secrets at all. If the permissions are loose, the binary refuses to start rather than logging a warning. A warning nobody will read is not a check.

The bootstrap follows the same rule. It does not copy another repository's install logic; it delegates to the owner. The moment you make a copy, the two begin to diverge, and the stale one always runs first.

Some things were reverted. I rebuilt the dashboard's information architecture wholesale, then rolled it back entirely and kept only the two changes that had proven their worth. Performance was fixed the same way. Removing the path that scraped external APIs the instant a user opened the page, and letting a background loop collect ahead of time, took one screen from 5.3 seconds to 10 milliseconds. Collect on the request path and the user pays every bit of that latency.

The industry evidence for this direction is [DORA's 2025 report](https://dora.dev/dora-report-2025/): AI is an amplifier, so strong teams get stronger and struggling teams fail faster, and one of the capabilities that unlocks its value is a quality internal platform. Measured against my own experience, the turning point was not the day I added a tool. It was the day I removed a surface.

## A golden path is paving, not design

Platform engineering textbooks say to lay the golden path first and put people on it. I went in exactly the opposite order. Onboarding came last.

I no longer think that was a mistake. The onboarding script took a day precisely because I had walked that path many times over the preceding half year. I already knew where it trips, what depends on order, and what has to be safe to run twice. That is also why verification was possible: I ran it end to end twice on a clean account. On a path nobody has walked, you would not even know what to verify.

A golden path is not something you design and lay down. It is what you pave when a road you have already walked has to be handed to someone else. Set the standard first and put people on it, and you usually end up pouring asphalt where no one has walked.

## The reader was not a person

Here the thought moves one step. The one who actually walked that paved road was not a person.

For an agent to read a document and execute it, the document and the system behind it need properties that differ from the human case. Those properties were already inside the earlier decisions.

```
# what the onboarding page had to guarantee for an agent to run it
1. one surface to call     - a single entry point, discoverable in one look
2. names that never move   - renaming a tool is a breaking change, not a cleanup
3. rerun-safe by default   - install and upgrade are the same command
```

One place to call, so the agent does not wander looking for what to invoke. Names as contracts, so calls stay stable. Idempotence, so a failure halfway through means simply running it again. I believed I had chosen these three for human convenience. They were, in fact, the conditions under which an agent could execute that page.

The industry calls this [Agent Experience](https://www.netlify.com/agent-experience/), a concept proposed in early 2025, built on three requirements: an agent must be able to discover, to invoke reliably, and to recover from failure. The order in which we felt pain was exactly those three.

What is interesting is that in Korea the same two letters carry a different meaning. Here, AX usually means AI transformation — redesigning an organization and its ways of working on the assumption of AI. Abroad, AX means agent experience — shaping a system's surface so agents can use it. One changes how people work; the other changes what the system exposes.

What I did was the latter. I did not reach transformation by remaking the organization. I shaved the surface, and the way people begin working changed.

## So what should be measured

Because the purpose of a handover was transferring understanding, onboarding was measured by understanding. How quickly did they grasp it? How much did the questions drop off?

Yet in the case above, that person began working without having understood the system. Understanding arrived later, and only as much as was needed. That changes what deserves measuring.

> The onboarding metric is no longer 'does this person understand the system' but 'can this person use AI to work on top of it'.

This does not stop at onboarding. The standard for documentation shifts along the same axis. A good document is now one a person can read and understand and one an agent can read and execute. That adds an item to the checklist when writing setup instructions, and it is not an item review catches. Hand the page to an agent and it surfaces within ten minutes.

## Closing

Read purely as a win, this conclusion is dangerous. That a person can work without understanding the system also means there is no preparation for the moment understanding becomes necessary. When the environment an agent built starts behaving strangely, that person does not know where to look first.

So executability has not replaced understanding. It has deferred it, and deferred understanding is billed with interest when something breaks. More precisely, understanding has moved from an entry condition to an operating condition. It is no longer required to start, and still required to continue.

In an [earlier post](/en/blog/delegating-issue-handling/) I wrote that the direction of automation is not lifting people out of the chain but moving where they stand from execution to supervision. This is that shift reaching as far as a new joiner. The person who joined did not execute the setup. They started from the seat where the result is supervised.

A bootstrap builds an environment. It does not build judgment. What fills that seat is the next problem.
