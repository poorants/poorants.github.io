+++
title = "How MCP Became the Standard"
date = 2026-06-04T10:00:00+09:00
draft = false
tags = ["mcp", "protocol", "json-rpc", "architecture", "claude-code"]
+++

In [the previous post](/en/blog/mcp-server-has-no-llm/) I argued that an MCP server is just an adapter with no intelligence of its own. Once you frame it that way, a new question appears. There are countless ways to build a dumb adapter that wraps some service's API. So why did this one convention, MCP, take the seat of the standard that connects LLMs to tools? The answer is not some flashy feature. It is in how the protocol was designed.

## It Did Not Invent a New Format

The first thing you notice is that MCP did not invent a new wire format. It sits on top of the already-proven JSON-RPC 2.0.

There are only three kinds of messages in play. A request that expects an answer, the response that comes back paired to that request, and a one-way notification that expects no reply. The transport layer that carries these messages sits separately underneath. Locally it is stdio; remotely it is HTTP. The grammar of the upper layer stays the same no matter which transport is used.

Not inventing a new format is not laziness; it is strategy. Code that handles JSON-RPC already exists in every language. It is a deliberate choice to drop the barrier to entry all the way to the floor.

## A Structure Split in Three

The two ends of a connection are split into three roles.

- Host: the app that holds the LLM. Judgment happens here.
- Client: the part inside the Host that maintains a 1:1 connection to a single server. If there are several servers, there are just as many clients.
- Server: the side that exposes tools. This is the dumb adapter I described in the previous post.

The line from the previous post, "the LLM is not in the server but on the calling side," maps onto this structure. The intelligence lives in the Host, and the Server merely carries out its instructions.

## The Server Describes Itself

What a server exposes is not just one thing. Tools that the model calls, resources that the app reads, prompts that the user chooses. The design splits them by who is in control. The core of these is the tool, and the core of a tool is self-description.

Ask a server for its list of tools, and it returns each tool's name, description, and input format as JSON Schema.

```json
{
  "name": "create_document",
  "description": "Create a new document",
  "inputSchema": {
    "type": "object",
    "properties": { "title": { "type": "string" }, "text": { "type": "string" } },
    "required": ["title"]
  }
}
```

This one fragment says two things at once. First, here is why you never have to write a separate usage manual. The schema itself is the calling convention, and the model reads it to fill in the arguments. Second, what the schema declares is only business data like the title and the body. There is no place for credentials to slip in. In the previous post I said you do not load secrets into tool arguments; that principle is, in effect, baked into the very shape of the protocol.

## It Starts With a Handshake

When a connection opens, you do not put it straight to work. First there is a handshake.

The client and server exchange `initialize`, trading their protocol versions and the capabilities each one supports. Who holds tools and who can read resources is agreed upon before anything starts. This negotiation is the basis of extensibility. Because both sides line up what they support up front, old connections do not break when new capabilities are added.

Unlike REST, where you exchange a request and a response once and are done, an MCP connection lives on as a session. So the server can also send a notification on its own that the tool list has changed. Instead of waiting to be asked, it pushes the state change.

## Folding M×N Into M+N

That covers the structure. And this structure leads to the real reason it became the standard.

Before MCP, connecting a tool to an AI app was a custom job every time. If there were M apps and N tools, you needed M times N integrations to connect them. One app's plugin format differed from another's, and the tool builders had to wire up to each app separately.

MCP turns this multiplication into addition.

```
Before:  M apps  ×  N tools  =  M×N custom integrations
After:   one client per app  +  one server per tool  =  M + N
```

The tool builder writes an MCP server once, and every compatible app can use it. The app builder implements a client once, and reaches every MCP server in the world. Either way, a single implementation opens out toward both sides entirely.

This is not a new idea. It is exactly what USB did for peripherals, and what the LSP (Language Server Protocol) did between editors and language tools. When there were M editors and N languages, LSP folded that multiplication into addition, and MCP carried the same pattern straight over to wiring tools to LLMs. There is a lineage to the way standards take hold.

## Closing

MCP became the standard not because it is the cleverest convention. It did not invent a new format, so getting in was easy; it borrowed the proven M+N pattern; and above all it folded the multiplication of integration into addition. A standard usually becomes not the most clever thing but the thing that plugs in the most places.

Let me draw one distinction. The model deciding "I will call this tool" is a capability of the model itself. MCP is the convention that standardizes, across process boundaries, where that tool lives, what it looks like, and how it runs. They are different layers, meshed together as a pair. If the previous post was about when to use MCP, this one was about why that MCP has the shape it does now. For one dumb adapter to become the standard, the clever part was never the adapter, but the design of the convention that connects it.
