+++
title = "An MCP Server Holds Credentials, Not Intelligence"
date = 2026-06-04T09:00:00+09:00
draft = false
tags = ["mcp", "llm", "architecture", "security", "claude-code"]
+++

There is a SaaS tool we use internally. I wanted to hand the AI the job of writing and editing content inside it. While looking for a way, the word MCP kept coming up, so I decided to wire it in. But the moment I actually reached for it, three unsettled questions stuck in my head.

- What on earth is inside this MCP server?
- How does my project connect to it?
- Once connected, how does the project use it?

The three questions had really branched off from a single misunderstanding. Once I stripped that misunderstanding away, all three resolved at once.

## An MCP Server Has No Intelligence

The misunderstanding is this: the belief that something smart, an LLM, lives inside the MCP server.

Because of those three letters tacked onto the name, the server seems like it will reason things out on your behalf. It does not. An MCP server is just a thin adapter wrapping some service's API. When a request like "create a document" arrives, it calls that service's creation API — a converter without a shred of intelligence.

The LLM is not inside the server. It is on the side that calls the server.

```
[LLM]  ←MCP protocol→  [MCP server: dumb adapter]  ←API→  [actual service]
intelligence is here              no LLM
```

What to use, when to call it, how to fill in the arguments — those judgments belong to the LLM on the calling side. The server receives the result of that judgment and executes it mechanically. Once I accepted that one line, the three questions that had snagged me began answering themselves in turn.

## Question 1 — What Is Inside the Server

If not intelligence, then what? Credentials.

The actual service the MCP server wraps does not let just anyone call it. A token or a key — that service's authentication is required before the API opens. So the MCP server operates holding those credentials. Whether they are injected as environment variables at startup or read from configuration, the credentials live inside the server runtime. The server's true identity is not something intelligent; it is a proxy that holds the credentials and calls that service on my behalf.

This is where I stayed confused the longest. To distinguish the author you need authentication — so does that mean I have to pass that information along every time I call a tool? The picture of putting an id and password in the request body.

The answer is clear. You must not, and you do not need to.

A tool call's arguments all pass through the LLM's context. The model reads them, they remain in the conversation history, they get printed to logs. Put credentials there and the secret leaks down every one of those paths. The LLM should be treated as sitting outside the boundary where secrets may be seen. So credentials stay inside the server, not in the tool arguments. The calls the model makes carry only business data, such as a post's title and body, and the server handles authentication with its own hand. The model never once sees the token.

To sum up, what the server holds is two things: how to call the service it wraps, and that service's credentials. Intelligence is not on the list.

## Question 2 — How My Project Connects

When you say "connect," it is easy to picture installing a library and writing code. Not here. It is registration.

You drop a single config file in the project path and write: launch this MCP server in this way. That is all. The client (Claude Code, for instance) reads that config when it begins work in that project and recognizes the server.

There are two ways to launch the server.

- stdio: the client spins the server up as a child process when it needs it and shuts it down when the work is done. There is nothing to keep running in advance. The notion of an always-on server does not even exist here.
- HTTP: you write down the address of a server that is always running somewhere and connect to it. This one requires the server to be brought up first.

For a tool you use alone on your own machine, stdio is enough. There is no reason to keep a server always running. Write only the launch method and the credentials (Question 1) into the config file, and the client spins it up and shuts it down on its own when called. Connecting is less like wiring and more like plugging in a single pointer.

One security aside. If that config file gets committed to a public repository, do not write the credentials directly there — have it reference an environment variable instead. Keep secrets outside the code.

## Question 3 — How a Connected Project Uses It

Once registration is done, you do not have to write a separate usage manual. This part was the most unfamiliar.

The server itself announces the list of tools it holds, each tool's description, and its input format. The client's LLM reads those descriptions and knows which tool to call and how. So a person only needs to give instructions in natural language. Say "make me a document out of this content," and the LLM picks the right tool, fills in the arguments, and calls it. The guide on how to call it lives inside the tool description.

Still, you have to separate what is automatic from what is not. Which tools exist and how to call them is automatic. But when they should be called and what our team's rules are is not automatic. That judgment and policy has to be written separately in the project guidance document. A tool's signature alone cannot tell you the context.

Here comes the conclusion that runs through all three questions. There is exactly one case where MCP earns its keep: when a person gives instructions in natural language, differently each time, and an LLM interprets those instructions to pick a tool. If the behavior is fixed in code — something like sending fixed content at a fixed time — there is no room for an LLM, and MCP is one layer of dead weight. The test fits in a single sentence: who decides this behavior? A person's natural language, or a fixed value baked into code?

## Scalability — When It Grows Into a Team

So far the picture has been one person on their own machine. Widen it to a team and new demands appear, and only then do the heavier mechanisms start earning their keep.

The prime example is identity. If many people share one server and you have to record who did what, per person, a single shared token will not do. That token mashes every trace into one account. This is where two layers of authentication enter. One layer asks: who are you? It opens the server's door with the company's single sign-on (SSO). The other layer uses that identity as a key to call the actual service with credentials that differ per person. Only this way does the author come out recorded correctly, per person.

The point is order. This single sign-on, the always-on HTTP server, the central credential store — these are layers you add when scale demands them, not a foundation you lay from the start. Building them ahead of time at the solo stage is nothing but cost. When the team grows and you reach the moment you need to view audit logs in one place, that is when you raise one layer at a time.

## Closing

The answers to the three questions that snagged me turned out to be simple.

- What is inside the server is not intelligence but credentials.
- Connecting is not code but a single registration in the path.
- Using it is a person instructing in natural language and an LLM picking the tool.

And one sentence remains, holding up all three. Before wiring in MCP, the thing to ask is not a technology choice but the subject. Who decides this behavior? If it is not a person instructing in natural language each time, what you need is not MCP but just an API.

## Next Post

This post stayed with the question that separates when to use MCP from when not to. It never opened up the matter of what protocol MCP is actually built on, that it became the standard for connecting LLMs and tools. The inside of the protocol — the structure on top of JSON-RPC, the server's self-description, and the design that folds the multiplication of integrations into addition — is examined separately in the next post, ["How MCP Became the Standard"](/en/blog/how-mcp-became-standard/).
