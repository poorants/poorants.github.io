+++
title = "Putting MCP to Work Inside the Company"
date = 2026-06-06T08:00:00+09:00
draft = false
tags = ["mcp", "automation", "claude-code", "devlog", "workflow"]
+++

Lately I've been wiring MCP into our internal work, one piece at a time. Nothing as grand as standing up a platform — just enough to wrap a few internal services in MCP so the things I already do (handling issues, building and deploying, keeping docs in order) can be finished from inside Claude Code. After living with it for a while it stuck better than I expected, so here's a light writeup of how it went.

## Starting With Issue Handling

The first thing I wired up was issue management. I put our internal issue tracker's API up as MCP tools — give it an issue number and it pulls the detail and the comment thread. Then I went a step further. Instead of just calling the tool, I baked the whole flow into a skill: fetch an issue, analyze it, and carry it through to a fix. It reads the issue, narrows down what needs changing, and follows through to touching the code, all in one pass.

## Build, Test, Deploy

Once it's fixed, it has to ship. I build it, put it on the dev server, run a user test, and then deploy — and that deploy prep goes through a file server (webhard) MCP, a tool that uploads the artifact to the file server.

What I cared about here was permissions. MCP means, in the end, that the AI is holding the tools and moving them itself. So I couldn't let it touch the whole existing deploy system. I split permissions by path. The real release path got read-only — the AI can look, but it can't write. Write access is open only on the QA-handoff path used for testing. That one path is the only place the AI can upload a file.

This file server MCP got reused in a way I hadn't planned for. Later, when I was standing up a test service built on a different server library, I pulled in the same MCP as-is. A tool you build once gets used elsewhere — which is exactly the payoff of keeping it as a module.

## Auto-Commenting the Issues After Deploy

Once a deploy finishes, the issues I fixed this round need the handling notes and the deploy path written back to them. Do it by hand and you'll always miss one or two. So at the moment the deploy completes, each fixed issue gets its handling items and deploy path posted as a comment automatically.

## Docs Go to the Wiki

A fix doesn't end at the code. It has to live on as a dev note so the next person finds it. So I built a wiki MCP too, and had it push the dev note for each change straight to the internal wiki.

## One Module, Three Services Run Separately

To sum up: the internal MCP server is bundled as a single module. Inside it, three services — issue management, file server, wiki — each run separately, switchable on and off. I turn on only what I need at the moment.

And once I set this up at the user scope, it's available across every project, not just one. No reconfiguring per project. Install it once and it's there everywhere, so the more I use it the more useful it gets.

## Next Up: Test Automation

Having come this far, the how-to and the setup of MCP are reasonably in hand now. Which stirs up the next appetite. Beyond unit tests for our internal solution, I think I can take a run at automating the user-test side too. That's a story for a separate post.
