+++
title = "Building an AI Agent to Handle Issues End to End"
date = 2026-06-03
draft = false
tags = ["claude-code", "agentic-workflow", "automation", "devops", "issue-tracking"]
+++

I pasted three issue links into the chat, typed "handle these," and walked away. When I came back and opened the issue tracker, each of the three carried a comment explaining how it was handled and the deployment path on the test server. Two were in a state where I only needed to verify them before closing. One had been left undecided because the request itself was ambiguous, with the reason for holding written out.

This post is a record of how I wired that pipeline together: how far the delegation went, and where a human is still required.

## What It Means to Close an Issue

When we talk about handling an issue, we usually picture only "fixing the code." But the path an issue travels before it closes is long. You read the issue and interpret the intent, fix the code, build it, deploy it somewhere, confirm the behavior, report the result, and leave a record so it stays traceable. The code change is just one link in that chain.

This is exactly why automation has been hard. A different system interrupts at every link in the chain: the issue tracker, the build tool, the deployment server, the messenger notification. A person moves between them by hand, stitching the context together. That stitching labor is, in effect, the real body of issue handling.

## Hardening the API into a Skill

It started with securing the API of our internal issue reporting system. I picked out the endpoints to query issues, change their state, and post comments. Credentials weren't hardcoded; I separated them into environment variables. The first premise of delegation is handling credentials safely, and this separation carries over unchanged when the handling process later moves into CI.

On top of that I laid down a single skill. What it does is simple. Given an issue link, it analyzes the content, handles it, enqueues it to the done-queue, and drafts the comment to leave on the issue.

```
# issue-handler skill — one issue link in, a structured outcome out
1. fetch issue by link (analyze title / body / labels)
2. resolve the change (code / config / investigation)
3. enqueue to the done-queue
4. draft a result comment on the issue
```

The point is not that this skill "posts comments automatically," but that it "leaves the outcome in a structured form." A person should be able to skim that comment later and follow what was done and why. The comment is both the deliverable and the audit trail.

## Isolated per Queue Item, per Worktree

When you throw several issues at once, each one must not contaminate the others. So when issue handling is requested, the work is split per item into a separate branch and git worktree. Items in the queue are handled independently in their own worktrees, and the failure of one does not spread to another.

This isolation resembles a security mindset. Cage each unit of work in a sandbox and block any effect that crosses the boundary. It structurally eliminates any room for issue A's change to intrude on issue B's build.

## Done Means Deployed

I don't close an issue the moment handling finishes. At the point of the completion report, the built result is deployed automatically to the test server. And the verification is mine to do. The step of opening the deployed screen myself and confirming that the request was reflected as intended is deliberately left to a human.

Once my check is done, I then issue the command to mark it complete. The build and deploy scripts run, and when deployment finishes a webhook notification is delivered to our Google Chat work channel. Finally, when I instruct the issue-handling skill to finalize, each issue gets a result comment and a deployment-path comment registered separately. What was done and where it was deployed are written apart, so they don't get tangled when tracing things later.

## When It Isn't Simple, Make It Verify Itself

The first batch I ran manually was three items. Two of them were handled precisely, and one was held because the request itself was ambiguous. Stopping with a stated reason rather than forcing an ambiguous request through is, if anything, the more trustworthy behavior.

The two items that came in next had a different grain. They couldn't be wrapped up with a simple one-line code fix; they were only verified by confirming the actual screen behavior. Here I attached Playwright. I wove into the handling flow a process that launches the browser automatically, reproduces the scenario, and verifies on its own that the expected behavior appears. In the end that item reached resolution too.

And I wrote up that resolution approach as a document and registered it back as a skill asset. The point is not to solve by hand again next time a problem I've already solved once. This part matters. Automation works at compound interest not from a single handled item, but only when patterns of handling accumulate.

## Closing

Right now this pipeline is still at the manual-review stage. Every deployment passes through my eyes, and I'm the one who gives the completion command. Yet running even a single batch is enough to see the outline of the next stage.

As confidence in the verification accumulates, the point where a human steps in keeps getting pushed back. Attach a dashboard showing the issue-handling status, and let issues be bundled into chunks by time period and handled automatically, and the manager's role shifts from "the person who handles every issue" to "the person who picks out only the issues handled wrong or needing a different direction." From watching everything, to watching only the exceptions.

This, I think, is the true direction of automation. Not lifting the human out of the chain, but moving where the human stands from execution to supervision. The small loop I have now, throwing in an issue link and checking only the result comment, is the first square of that move.
