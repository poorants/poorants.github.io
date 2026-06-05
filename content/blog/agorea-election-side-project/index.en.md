+++
title = "agorea: A Side Project to See Who's on My Ballot at a Glance"
date = 2026-05-31
draft = false
tags = ["side-project", "go", "web", "seo", "growth"]
+++

There's a scene that repeats every election. The mailbox fills up with campaign flyers, names scroll past in the news, and yet it's hard to see at a glance: "So what am I voting for in my district, and what do the people running actually stand for?" Metropolitan and local executives, district and proportional council members, the education superintendent — one person has to mark several ballots, and the information for all of it is scattered everywhere.

So I built it. Not some grand service, but a single window to **check, easily and quickly, "who do I have to vote for, and what do these people stand for."** I named it [agorea](https://agorea.xyz).

This post isn't here to show off the result. I took a side project from zero to one entirely on my own, and I learned more outside the code than inside it — so I'm leaving a record of that.

## What I Wanted to Build

The goal was simple from the start. Type in a single line of address, and you get:

- the **types of votes** being held where you live this time,
- the **candidates** narrowed down to your electoral district,
- and each candidate's **campaign pledges**, all laid out on one screen.

It was never meant to be an encyclopedia listing every candidate in the country, but a tool that **narrows things down to "my own criteria."** The problem wasn't a lack of information — it was that there was too much of it, and picking out the part that applied to me was hard.

The value I wanted to share lives here too. I believe that lowering the barrier to reaching information, even by a single step, helps someone take part. The act of voting feels weighty, yet the information hunt that precedes it is far too tedious. I wanted to close that gap.

## Where the Data Comes From

The data comes from **public data — the National Election Commission's OpenAPI.** Candidate lists and pledges alike only earn trust if they come from an official source. I won't dwell on this part. The source is a public institution; for the purposes of this post, that's enough.

## Building It and Keeping It Standing Are Different Things

Getting the features to work wasn't hard. The problem came after. **Working** and **operable** are completely different problems, and this time I felt that in full.

One representative case: the screen showing legislative-activity statistics initially ate close to 1GB of memory per request. Left as is, the server would buckle the moment people showed up. Switching to a scheme that stored precomputed results separately brought the same screen down to 16MB. Users never see this difference with their own eyes. And yet it's what decides whether the service lives or dies.

It wasn't only performance. Keeping data from getting tangled when several people enter at once, hardening a publicly exposed server even a little — performance, security, and concurrency, in other words — these were things I seriously grappled with for the first time on this project. Making something run and making it endure are different jobs.

## Building It Isn't the End — It Has to Be Found

This was the point I agonized over the longest on this project.

No matter how easy and well-built it is, **if it doesn't reach people, it might as well not exist.** Making it visible in search, registering the site with search engines, observing who actually comes in and how — without writing a single additional line of code, the work piled up like a mountain. I had always thought of the end of my job as "deployment," and this time that line moved. Development ends not at deployment but at reach.

The story of search visibility and reach runs fairly long, so I plan to cover it in dedicated, part-by-part detail in future side-project posts.

## A Question Beyond the Code — There Isn't Enough Time to Check

Independent of the code, working with the data made the schedule itself jump out at me.

- Candidate registration deadline: May 15
- Election bulletin (pledge) submission deadline: May 22
- Election day: June 3

In other words, candidates and pledges aren't fully in place until late May, and the time a voter has to look them over is two weeks at most. For an office worker coming home after overtime, that's tight for calmly comparing the candidates and pledges across seven ballots. The whole time I was building, the question kept coming up: "Is this schedule reasonable?"

Looking into it, this turned out to be a structural feature of the Korean system. Korea's Public Official Election Act deliberately keeps the official campaign period itself short (13 days for local elections). It's an intended design to curb cost and overheating, not an oversight. The U.S., by contrast, has no concept of a Korean-style "pledge submission deadline" — candidates disclose and debate policy over months, including primaries. The longer runway comes with its own trade-off: more money and more fatigue.

If Korea chose the short, compressed side, then it needs a tool that lets you skim candidates and pledges quickly within that short window. That's exactly the point where the reason for this project locks in.

## When a Number Becomes the Evaluation

Looking through the legislative-activity data, one more thing caught my eye: at some point, the number of bills introduced by National Assembly members grew noticeably.

The number of bills introduced feeds into the score used to evaluate legislative activity. I understand the intent — show how much work got done as a number. But a quantified qualitative evaluation tends to degrade, in the end, into "a means of scoring well."

It plays out like this. You think of one good item to propose, but for the sake of the score you deliberately split it into several separate bills. The count goes up, but the weight any single item carries thins out. The numbers get filled in while the substance blurs — I wondered whether all that's left is that kind of side effect.

I don't think evaluations at work are any different. Whatever the methodology, it should stay a means to raising the quality of the project. The moment it becomes an evaluation item in its own right, like a test question, people stop moving toward doing good work and start moving toward scoring well. And then the original purpose is lost. It's a personal thought, unrelated to the features, that came up while handling the data.

## The Next Stretch — Beyond the Election

I have no intention of letting agorea end as a one-off site that has served its purpose once June 3 passes.

The election is only the start. What I'm more curious about next is how the policies of the country we live in actually get made and run. The foundation I laid this time — the structure that gathers candidates and pledges, handles legislative-activity data, and presents it as statistics — can be extended as is into a screen that follows the flow of policy.

So the next chapter of this project isn't the election but **policy.** Not to police who's doing well or badly, but a small policy dashboard for myself — one that lets me calmly track, on a single screen, where the country's policies I've long cared about currently stand.

On June 3, before you vote, take a moment at [agorea.xyz](https://agorea.xyz) to check what your neighborhood is voting on.
