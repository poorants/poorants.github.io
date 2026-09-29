+++
title = "Silence You Can Trust — A One-Person Alerting Setup, Built by an Agent"
date = 2026-09-29T00:00:00+09:00
draft = false
tags = ["automation", "ai-agent", "claude-code", "monitoring", "telegram-bot"]
+++

On September 28, after a Docker upgrade, the reverse proxy on one of my servers went into a restart loop. CPU, memory and disk were all fine. Anyone looking only at resource graphs would have seen an uneventful day. What made my phone buzz was the HTTP check sitting right next to them.

Build any automation that sends alerts and you hit the same problem quickly. **"Nothing to report today" and "the thing that reports is dead" are equally quiet.** A morning with nothing on your phone might be a calm morning, or a morning where the watching stopped. An alerting system is only useful once that silence can be trusted.

These days a handful of small watch jobs run on my personal servers: monitoring in which three servers watch each other, a watch for cancelled slots at a hard-to-book venue, and a watch over the support inbox and store reviews of an app I run. All of it lands on my phone through one Telegram bot. And I didn't write this code. A Claude Code agent did, from design to deployment. What I decided was what to watch, what must never be done, and whether the results could be trusted. This post is a record of the shape that setup converged on.

## The only human steps were identity and consent

Looking back, the steps where a person actually touched anything were remarkably few. And every one of them was **something that needed my identity or my consent**.

- Creating the bot with `@BotFather` in Telegram, and sending that bot the first message. A Telegram bot can only message a person after that person opens the conversation.
- Putting the issued bot token into a secrets file on the server.

Everything else was the agent's. It checked the token, found my chat id, got the message format right, wrote the service units, deployed, and confirmed that the first message actually reached my phone. On the day the first bot went in, the agent's lookup came back empty right after I said I'd messaged the bot. It didn't conclude failure; it checked the pending update count separately, and a moment later the message showed up. Telegram had simply been slow to deliver.

That boundary stayed in the design. Each job's deploy script **never writes a secrets file, and refuses to enable the timer while a secret is missing.** The agent can redeploy as often as it likes; the token stays a value a person fills in.

## One folder, one timer, one notification

As the jobs multiplied, they needed a shape. The rule I set fits in one line: **one small program + one timer + one notification.** A job that grows a screen or its own database moves out into its own repository. Under that rule, this is the structure the agent built.

```
automations/                      # one repo, one folder per job
├── infra-watch/                  # servers watching each other
├── booking-watch/                # cancelled-slot watch
└── business-watch/               # support inbox, store reviews, deadlines

/opt/automations/<job>/           # on the server
├── <job>.py                      # standard library only
├── .config/                      # secrets — filled by a person, never by deploy
└── state/                        # what was already announced, last error

auto-<job>.service / .timer       # systemd, one-shot + timer
```

There is no shared library. The code that sends to Telegram lives separately in each folder. When the cost of an agent writing code approaches zero, **keeping the jobs ignorant of each other** is worth more than removing duplication. Fixing one job can't break another, and a finished job disappears by deleting its folder and units.

## The agent hands its traps to the next job

On the day the first Telegram alert went in, the agent wrote every snag it hit into a document in my knowledge store (the brain): that an unescaped special character makes the whole alert vanish, that photo captions are cut at 1,024 characters, that when an image can't be fetched the alert must still arrive as plain text.

The next day, the second job — the cancelled-slot watch — went in on the same pattern. Its README covers bot setup in one line: see that document in the brain. That same afternoon, while polishing the server watch's morning report, three new traps were added to the same document — including the fact that Korean text in a fixed-width table throws the columns out of alignment.

When a person builds alone, traps live in their head, and by the time the same job comes around three months later they've blurred. An agent remembers nothing once a session ends — but in exchange, **you can make sure it never skips writing down what should be remembered.** The next job starts from that document.

## Making silence trustworthy

Once there's a channel, the next question isn't what to send. It's **whether you can trust the silence when nothing is sent**. Every job got the same five mechanisms. I set the principles; the agent fitted the implementation to each job.

- **Send something once a day even when there's nothing to do.** The server watch sends yesterday's check count and anything still open every morning; the cancelled-slot watch sends how many times it checked and alerted yesterday. That summary is the heartbeat. If it doesn't arrive, its absence is the alert.
- **Alert on a failure once, and on its recovery once.** If the same error arrives every five minutes, a person soon mutes the chat — and from that day on there is no monitoring.
- **The first run only takes a baseline.** The first time the inbox watch runs, hundreds of existing messages are all "new mail". The first run stores a snapshot and sends a single message.
- **Servers watch each other.** A dead server can't announce its own death, so its neighbor does. If both die, that morning's summary doesn't come. The heartbeat is the last net.
- **Don't watch only resources.** The outage at the top of this post is why. A healthy server and a responding service are different questions, so HTTP and container checks sit right next to the resource checks.

And one more was added later. **If there's nothing to send, fail instead of sending.** There was a day when a config went out incomplete and a report with only a title was delivered. The log said "sent successfully". By the logs the agent could see, it was a success; I only noticed something was off when I looked at my phone. What an agent can verify stops at the signals the machine leaves behind. The rules that keep those signals from lying had to be found by the person receiving the results.

## When data lies, check the source once more

The cancelled-slot watch produced the opposite problem: alerts that were too loud.

One day a particular time slot showed as "available" for hours. It turned out the venue had switched off online booking altogether. The schedule query kept listing open seats anyway. The schedule described seat inventory; it said nothing about whether bookings were being taken.

So now, when an open seat appears, the job fetches the venue's page once more to confirm booking is actually open. As a principle: **when a signal arrives, check at the source that the action it points to is actually possible.** An alert that leads you somewhere with nothing to do erodes trust in the whole channel.

## Automation stops at notifying; people act

There was one line I held throughout while handing this to an agent. **The bots never do anything hard to undo.**

The inbox watch only applies labels. It doesn't send, draft or delete. Telegram gets the sender, subject and a link to the mail — never the body. The alert channel is less protected than the mailbox, and the moment the body is copied over, the channel becomes a copy of the mailbox. The cancelled-slot watch never books on my behalf. The venue requires bookings to be made from the visitor's own account, and automated booking breaks the platform's terms anyway.

That line has two layers. Just as the bots the agent built don't act on a person's behalf, the agent that built them doesn't handle credentials on a person's behalf. The inner layer only observes and relays; the outer layer only implements and deploys. Judgment and consent stay with the person in both.

## Wrapping up

Looking back over these jobs, the code that does the actual "work" is small. Querying a schedule, applying a label, checking a status code — those parts are short. Nearly everything else is **machinery that gives silence a meaning**: the daily summary, the failure and recovery sent once each, the exception thrown on an empty body, the second look at the source, the timer that won't start without its secrets.

The agent wrote the code for all of it. But which silences not to trust could only be known by the person holding the phone. The empty report behind a "sent successfully" log was caught by the one receiving it. Handing work to an agent doesn't mean letting go; it means the place where you put your hands moves from implementation to **receiving the results and fixing the rules**.

In the next post I'll write about adding one more layer on top of this: a model. A morning briefing that gathers 33 feeds and summarizes them with `claude -p` — and why that briefing went quietly silent for nine days.
