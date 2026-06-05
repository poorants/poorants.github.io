+++
title = "I Stopped Deciding Where to Put Each Document"
date = 2026-06-01
draft = false
tags = ["para", "claude-code", "agentic-workflow", "knowledge-management", "productivity"]
+++

I was about to save a note on something I'd just learned, and I paused in front of the folder list. Where should this go so I can find it again later? Under `docs`? Inside the project folder? Or should I carve out a separate `notes`? After a second of hesitation I drop it somewhere, roughly. And two months later, I have no memory of where I put it.

It's a trivial hesitation. But this moment returns every time I try to turn something into an asset. When I write up a newly adopted technology, when I finish a key piece of work that will be a handoff point, when I file away the research I gathered before starting new development. Every time there's something worth recording, the same friction repeats, and running several projects alone, this small decision piles up everywhere. Worse, classifying by mood in the moment blurs the rules, until later I can't even search for the thing.

The problem was clear. I had to decide, every single time, where this document goes, and then I had to remember that decision. I didn't want to do either.

## Classifying by Topic Splits Forever

The most common way to classify documents is by topic. `frontend`, `backend`, `infra`, `research`… but topic classification splits without end. It's common for a single document to straddle two or three topics. Is "notes on evaluating a message queue" filed under `message-queue`, `architecture`, or `research`? There's no right answer, so I end up deliberating anew each time.

Topic is too slippery to use as the axis of classification.

## PARA — Divide by Action, Not Topic

PARA, proposed by Tiago Forte, solves this problem on a different axis. It divides every document into just four bins.

- **Projects** — active work with a deadline and a goal
- **Areas** — ongoing domains of responsibility that never end
- **Resources** — material to reference someday
- **Archives** — things that are done or have gone inactive

The key is that the criterion is not "what is this writing about (topic)" but "how close is it to my current action (actionability)." The same API document is in Projects if it belongs to a feature I have to finish this quarter, and in Resources if it's reference for a system I maintain on an ongoing basis. Not the topic of the writing, but what I'm doing with it right now, decides its place.

What makes this shift elegant is that classification, which used to split forever, converges to four bins. Topics are uncountable, but "distance from action" lines up on a single axis: Projects → Areas → Resources → Archives.

That said, PARA still leaves one thing to the person: the judgment of whether a document is a Project or an Area. The rules became clear and finite, but applying those rules to each document was still my job.

## Clear Rules Can Be Delegated

Here my thinking moved a notch. The virtue of PARA is that its rules are clear and finite. And rules that are clear and finite — can be delegated.

If the criterion for judgment fits in a few lines, like "if it has a deadline, Projects; if it has no end, Areas," there's no reason I have to be the one making that call. I only need someone I can hand the rules to, written down plainly. As it happens, such a counterpart had arrived: an agent that reads code, makes judgments, and writes files.

## Solidifying the Rules Into a Skill

So I turned the PARA classification rules into a Claude Code skill. I named it para-docs. When creating a document, the skill settles its place through a few questions.

```
# para-docs picks the category from a few yes/no questions
- Has a deadline or a specific goal?      → Projects
- An ongoing responsibility, no end date? → Areas
- Reference material for later?           → Resources
```

Now the flow is simple. When I say "leave a document for the technique I just wrote up," the agent reads the content, decides the classification by the rules above, and saves it in the right bin with a `kebab-case` filename. I don't decide where to put it, or under what name.

I tweaked one more thing so this skill works the same way across every project. Different repositories have different folder conventions. Some put `projects/` and `areas/` right at the root; others gather them under `para/`. When the skill starts, it inspects the root and detects on its own which approach the repository uses, then adapts. Thanks to this, even when I move into a new project, documents get organized the same way immediately, with no setup.

## When the Commit Log Becomes the Document

The flow I actually use most often is this. I build something over a day or two, stack up a few commits, and then there are times I want to leave a record of that work. So, right where the work ends, I say this.

> "Skim the commit log from the last three days and leave a document on this technique, from this angle."

Then the agent reads the commit log for that period, distills what was done, organizes it into a document, and saves it in the right place according to the PARA rules. I don't have to recall each commit one by one, and I don't decide which folder the writing goes into. The raw material of the record (commits) and the rule of classification (PARA) are already there, so all the person does is say in one line "what, and from which angle."

The real reason documentation keeps getting postponed is not the writing itself, but the friction on either side of it — retracing what was done, and deciding where to put it. Hand both sides to the agent, and recording stops being a task and becomes a single sentence.

## The Hesitation That Vanished

The change looks small but it's decisive. Now, when I create a document, I don't agonize over "where do I put this so I can find it later." Answering that question is the agent's job, and the agent always answers by the same rules.

The division of labor between human and automation split naturally. What to write, and its content, the human decides. Where to put it, and that place, the rules decide. Because consistency comes from the rules rather than from a person's willpower, I also don't need to wonder where I'll find the document two months from now. When the rule is constant, the path to find it is constant too.

## To Try It Yourself

This skill lives in the public marketplace [poorants/ant-skills](https://github.com/poorants/ant-skills). Register the marketplace with Claude Code and install it.

```bash
claude plugin marketplace add poorants/ant-skills
claude plugin install ant-project-kit@ant-agent-skills
```

After installing, in your project just say "organize the docs" or, as above, "read the commit log and leave a document." If PARA folders already exist at the root, it follows that structure as-is; if not, it creates them and gets started.

## Closing

PARA was originally built to reduce a person's decision fatigue. Lay an agent on top of it, and the decision that had merely been reduced disappears altogether.

In today's terms, this is a very small practice of agentic workflow. Not some grand automation — just picking one task with clear rules and handing it to the agent. But because that one thing was a trivial friction repeated every day, the felt difference isn't small. I leave classification to the rules, and stay only with the writing.
