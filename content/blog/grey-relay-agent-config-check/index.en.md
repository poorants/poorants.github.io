+++
title = "After reading about a 'grey relay' that quietly proxies coding agents, I checked my own machines first"
date = 2026-11-26T00:00:00+09:00
draft = false
tags = ["ai-agent", "claude-code", "security", "homelab", "tailscale"]
description = "A service installs the real Claude Code and Codex, then routes their requests through its own server. I checked my own machines and added a hook."
+++

While skimming AI stories that were trending overseas, I stopped at a Symantec report. A service installs the genuine Claude Code and Codex CLIs on a user's machine, and once they are in place it quietly changes four settings. It points the address requests go to (`ANTHROPIC_BASE_URL`) at its own server, turns off the sandbox, swaps the original credentials for its own token planted in an environment variable, and then switches telemetry off as well. From then on, prompts, the files the agent reads and the commands it runs all pass through that server. About a dozen organizations were confirmed affected, and one of them was a subsidiary based in Korea.

What scared me was that the tools are real. The CLI you always use runs the way it always does, and since only a few lines of configuration have changed, there is not much for the person using it to notice. I have a machine that runs agents every day and connects from there to my own servers, so it was hard to treat this as someone else's problem. I closed the report and opened up my own setup first.

## The dev machine: none of the four signs

I held the report's four signs up against my dev server one by one. I did not print any key values, only checked whether things were there or not.

No variable redirecting the request address was set anywhere. I went through the current shell and the login shell, and on into `.bashrc` and `/etc/environment`, and the name never came up. The `env` block in my Claude Code settings held a single build option, and since I sign in with a subscription account there was no key baked in either. Codex had no config file at all, and no variable was turning telemetry off. I also went through the registered MCP server addresses one at a time, but none were unfamiliar, and there was no stray `AGENTS.md` lying around in the Downloads folder.

I did turn up one small thing: there were two `claude` executables. The one actually in use was the official install, but an old version I had installed with npm in September was still sitting in `/usr/bin`. Nothing uses it, so it is not a problem today, but after reading that report it bothered me that I could not answer "which claude is the one running right now?" straight away.

![The dev machine check. The request-address and credential variables are empty; only the permission mode stands out as bypassPermissions](relay-check-devbox.webp)

## But one door was already open

What actually got flagged was a door I had opened myself. Claude Code's permission mode was set to `bypassPermissions`, and it was also configured to skip the dangerous-mode confirmation. I had turned that on long ago because I got tired of pressing the approve button every time.

That, though, is exactly the state a relay is trying to create once it gets onto a machine: an agent that runs things without asking. I had done it to myself for convenience. Looking only at the config file, a door I opened for convenience and a door someone opened behind my back look identical, and nothing in the file records who wrote the line.

So I also looked at when the config file changed and what changed. It had changed twice that morning alone, which made me tense for a moment, but comparing it with the backup showed it was my own session adding a few allowed commands and blocking force-pushes. This time it was all me. I did make a note, though, that confirming it meant digging out a backup and diffing it.

## The server: three layers, and only one comment out of date

While I was at it I checked the server that machine connects to as well. My remote brain, my password vault and the hub that holds my personal keys all live on one server, and I had always said it was "only open inside the tailnet." When I actually checked, the only things accepting connections on the public address were the web server's ports 80 and 443, and the three services were bound to `127.0.0.1`, reachable only through a single tailnet path. The firewall was also dropping incoming connections by default, so there were three walls in all.

But there was a comment in the brain's front-end config saying "reads now work without a token." For a moment I thought all my notes were wide open, but when I hit it directly without a token, everything came back `401`. It turned out that switch had been closed two months earlier and only the old note was left behind. I updated the comment to match the current state, and while I was there I also narrowed the public site's app, which had been accepting connections on every network interface, down to `127.0.0.1`.

## What to watch from here

What I learned this time is that the place this kind of attack goes after is configuration, not code. One line for the request address, one for the permission mode, one for an environment variable is enough. As long as the agent reads that file and does what it says, whoever can change the file controls the agent, and the trouble is that there is no way to tell whether a given line was written by me or by someone else.

So I added a check to the plugin hook that is installed on each of my machines. It looks at two things when a session starts. First, if a request address is not an official vendor host, or the Codex sandbox is off, it warns at every session until that is fixed. Second, if any setting that decides where requests go or what is permitted (`env`, the key helper, the hook list, the permission mode) differs from the last session, it names which item changed, once. It never keeps any values, only a hash prefix for comparison, because a mechanism meant to guard settings that hold keys should not be holding those keys itself.

To try it, I made a throwaway home directory and imitated exactly what a relay does. I put a relay address into the settings, turned off the Codex sandbox and opened a session, and the warning was right there on the first screen.

![In a throwaway home, after pointing the request address at a relay and turning off the Codex sandbox, the warning shown when a session opens. Changed items appear by name only](relay-hook-warning.webp)

This hook does not block anything; it only lets me know the moment something changed. If I made the change, I can say "yes, that was me" and move on, and from then on that state becomes the new baseline. I left the permission mode I opened for convenience as it is, but now if anyone touches that line I will know at the next session.

## Wrapping up

To sum up, no relay signs turned up on the dev machine, and the server was only open inside the tailnet, as I had thought. What I changed was an outdated comment on the server, the bind address of the public app, and one hook that tells me when settings change. I kept the permission mode open as I use it now, and wrapped up this check by making sure I will know if anyone changes it.
