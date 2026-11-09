+++
title = "Moving MCP to a server ended our 'please update' messages"
date = 2026-11-19T00:00:00+09:00
draft = false
tags = ["mcp", "developer-experience", "claude-code", "platform-engineering", "security"]
description = "We moved our team's internal MCP from each PC to one server. Update notices are gone, new hires start in minutes, accounts and tokens live in one place."
+++

I build and run the internal MCP my team shares, and the thing I did most was not building tools. Every new version meant a "please update" message to the team. Even then, I had to check separately who was still on the old one. When someone new joined, I handed them a 300-line setup document. An agent did the actual running for them, but keeping that document correct for every version was my job. To get rid of that work, I took the MCP server off everyone's PC and moved it to a single server.

Once it moved, almost all of that work went away. A new version needs no announcement: I deploy the server, and from the next session everyone is on it. A new person gets one setup page and lands straight in the team's AI setup. Accounts for internal systems are managed in one dashboard, and registration is two lines with one token. Access control and a call log came along for free, though I never set out to build them.

## No more "please update"

One day in October, the internal MCP server changed versions several times in a single day. It was the day tools for team calendars, meeting-room booking and expense claims went in one after another. I sent the team no notice that day, and nobody reinstalled anything. Whoever opened their next session simply had the new tools.

Before, every version change sent out a notice: put your token in your shell, rerun the install script, open a fresh session. Sending the notice told me nothing about who had actually done it, and every version change meant editing the setup document too. Eventually I had the local server append a line to the first response of each session saying a new version was out. Pulling and installing it was still up to each person.

With one server, one deploy is everyone's update. The plugins update themselves when a session opens. One manual step remains: if the small binary the hooks use falls behind, the session says so first, and you run the setup command once more. I didn't keep the old path around. Over two days, an agent stood up the remote server and deleted the local server and several thousand lines of install scripts.

## New people land straight in the team's AI setup

What a new person gets now is one setup page. It opens with four commands, and below them it says "read the rest only if you get stuck." Log in to the dashboard, enter the accounts for the systems you'll use, and get a token. Paste two lines. Run the setup command in a session. Restart. The team's MCP tools, the shared knowledge store, the team's common plugins and rules all attach at once. The time estimate on the page says 10 minutes. You know you're done when `claude mcp list` shows both servers as `Connected`. Before, you launched the installed binary by hand and checked its output: how many variables it had read from the credentials file and which services were enabled. The knowledge store needed a separate diagnostic command.

Before, you read a 300-line README from the top. You met four prerequisites, ran the install script through eight steps, and filled in eleven values in a credentials file by hand. For some of them you had to ask the team where to get them. Windows had its own script. A good part of the README was a list of traps. If a temp file name collided with another account on the same machine, the download hung. If your shell wasn't bash, the install command threw a syntax error. On an older PowerShell, the Korean in the instructions was installed garbled.

Now those traps have nowhere to live. There is almost nothing to install on the machine, the two registration lines are identical on Linux, macOS and Windows, and no step asks for admin rights. People on the old setup moved over once. The migration page estimated 20 minutes. They copied their values into the dashboard; removed the MCP registrations, plugins, binaries, config folders and caches the old install had left; removed the token in their git credentials file and the instruction block wedged into their user instructions file; then pasted the same two lines a new person does. That is how far the old setup had spread on a single person's machine.

## Accounts in one dashboard

On a password-change day, I used to edit the credentials file on my laptop, then log in to the dev server and edit the same file again. The day we started using a new issue tracker, I entered the value on every machine I used and reconnected each session. For some systems, entering the value still left the tools silently missing, because the registration command needed an extra argument.

Now I edit the internal-system account field in the dashboard once. Within 10 minutes at most, every machine uses the new value from its next session, and tools for any newly added system show up. Each field links to the page that issues the value and shows an example, so you find where to get it from inside the field itself. The home screen counts how many systems you haven't filled in yet. Fields are validated as you enter them. For a messenger notification URL, it checks the host and path are the expected ones and that the same room isn't entered twice, and when the check fails, the error message doesn't echo the URL back. A saved password is never shown again. The server receives that person's values when a call comes in and holds them only in memory; the agent never sees a password.

## Registration with one token

You get a token from the dashboard once. If you tick where you'll use it when you create it, the issue screen hands you one registration command per destination, token already filled in. Our team connects to two places, the MCP for internal systems and the team knowledge store, so it's two lines, both with the same token.

```bash
claude mcp add --transport http --scope user <name> https://<host>/mcp \
  --header "Authorization: Bearer <token>"
```

A day when a token may have leaked also comes down to one task. Revoke it, and the next call is blocked. Get a new one and paste the two lines again. Before, one password file opened every system, so a leak meant changing the password on each of them. Now a token alone can't get a password out: pulling a value from the vault takes both the person's token and the requesting service's own key. The token design copies GitHub and GitLab personal tokens as they are. It's shown once right after creation, and the list shows when each was last used and from which address. If you miss the value, there's no way to see it again; you regenerate. Regenerating creates a new value with the same name and scopes and revokes the old one at the same instant. [engram](https://github.com/poorants/engram), which I've made public, does the same registration with a single browser login instead of a token.

## Access control and a call log came for free

Because the server identifies the person from the token on every request, each person now sees a different set of tools. Only tools for systems you've entered an account for are in the list. There's no need to fence off unusable tools in documentation. A session is bound to the owner of the token that opened it, and the server checks they still match on every call. A test pins down that you can't ride an already-open session with someone else's token. When someone leaves the team, I disable their account, and every one of their tokens is rejected on the next call.

Calls are recorded too. When I want to know how far yesterday's issue cleanup got, I open the call log in the dashboard. It lists, in time order, which tool was called, with what result, on what target, from which address. Targets are kept as identifiers, so I can see which issue got a comment and which document was edited, and the address column shows my PC's address, not the server's. Content such as document bodies is not recorded. Before, no record like this existed anywhere on the team. If I see a call I didn't make, I revoke that token right away.

## The new inconvenience

A remote server can't reach files on my PC. If I ask for a build artifact to be uploaded to the file server, the agent calls the tool, gets back a curl command with a one-time URL valid for 5 minutes, and runs it in my shell. To me it's one request, but under the hood it became two calls. I also turned off the login session cache that was fine when I was the only user. With several people on the same server, that one file could hand one person's login to the next.

A local MCP was fine without login. The passwords were in my home directory and I was the one calling. Moving to a server removes that assumption, so the server asks who's on the other end of every call. Both the conveniences above and the inconvenience come from that.

## Closing

In [An MCP Server Holds Credentials, Not Intelligence](/en/blog/mcp-server-has-no-llm/), I wrote that an always-on server and central credential storage could wait until scale demanded them. In practice, the trigger wasn't scale. Headcount stayed the same; the moment came when sending update notices, chasing old versions and keeping the setup document current started eating the time I had for building tools.

In [I Skipped the Handover](/en/blog/onboarding-without-handover/), I wrote that I'd gathered scattered passwords into one file in the home directory and that an agent did the new person's setup for them. A month later I removed that file, and setup became short enough not to need an agent. The users' work didn't disappear; it moved to one place, the server. I think that's the better trade. Work done in one place only has to be done right once.
