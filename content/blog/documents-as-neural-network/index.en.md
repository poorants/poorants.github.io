+++
title = "Documents as a Neural Network: I Put a Ruler to My Own 'Second Brain'"
date = 2026-06-16T00:00:00+09:00
draft = false
tags = ["knowledge-management", "second-brain", "zettelkasten", "networked-thought", "para"]
+++

Anyone who opens Obsidian's graph view for the first time tends to freeze at the same picture: hundreds of dots tangled in lines, slowly pulsing, like a cross-section of a firing brain. It's the exact screenshot every "second brain" pitch puts on its first slide. The promise: notes accumulate, they wire up like synapses, and at some point the system starts thinking for you.

I believed that promise and piled up notes for nearly a year. A year later my graph *looked* like a brain but behaved like a junk drawer. Plenty of dots, most of them isolated islands touching nothing, and the documents I actually needed I was finding through global search, not the graph. Between the slogan — "turn your documents into a neural network" — and what I actually held in my hands, there was a clear gap.

Curious about that gap, I decided to implement the whole discourse as code. It's a document tool I call engram. I translated what the foreign references preach into rules, and then bolted on **a ruler that scores my own brain against those rules**. The number it spat out embarrassed me, and this post starts from that number.

## What they're selling

The archetype here is the German sociologist Niklas Luhmann. Over his life he amassed about 90,000 index cards in wooden boxes — a Zettelkasten — and out of it produced some 70 books and over 400 papers. The point isn't the card count. Luhmann called the box not a mere store but a *communication partner*. He didn't think alone; he thought *with* the box, and because neither side knew what the other would surface, they could surprise each other. The claim: knowledge comes from association, not from search.

The people who dragged this lineage into the digital world are today's references. Andy Matuschak, under the name "evergreen notes," nails down three principles: notes should be atomic, concept-oriented, and densely linked. He goes further — "prefer associative ontologies over hierarchical taxonomies" — and lands the sharpest line of all: "'Better note-taking' misses the point; what matters is 'better thinking.'"

Add Tiago Forte's PARA (Projects, Areas, Resources, Archives), the bi-directional links and backlinks that Roam Research popularized and Obsidian made standard, and Nick Milo's MOC (Map of Content). The wording differs, but the proposition converges to one thing: **a tree (folders) imprisons information; a graph (links) lets you think.** Human memory works by association, not hierarchy — so make your documents do the same.

## Why "neural network" is only half a metaphor

First, let's dissect the metaphor honestly. The graph view is not a neural network. No weights, no learning, no activation functions. It's a static directed graph — nodes and edges, nothing more. Pile up notes all you like; the system never learns anything by backpropagation. That pulsing "firing brain" picture is, frankly, eye candy. People who've used these tools for years say as much: the graph view is pretty and nearly useless.

So what *is* brain-like? Not the visualization but **associative retrieval** — the property that one thought is reachable by many paths. In a folder tree a document lives in exactly one place; you reach it only via the single path "encryption / national-standard / KCMVP." A linked document, by contrast, is reachable from a compliance note, from a post-quantum-crypto memo, from yesterday's meeting log. The more retrieval paths, the more often that document resurfaces from a context you'd forgotten. That's the "surprise" Luhmann was talking about.

So: the marketing is the graph picture; the mechanism is multi-path retrieval. The picture comes for free. The retrieval paths someone has to lay by hand.

## I put a ruler to my own brain

Most note tools measure exactly one thing: **orphans** — documents with no inbound link at all. But having no orphans is only the floor of "connected"; it's no evidence of being brain-like. So I cut a second mark into engram's ruler: a **woven ratio** — the share of nodes pointed at, in context, by *another body document* rather than by a folder's MOC. And **lonely spokes** — nodes reachable only through their own folder's MOC: they pass the orphan check, but they're really just the folder tree redrawn as links.

I ran this ruler over my year-old brain. Orphans: **zero**. Full marks on the textbook test. Yet the woven ratio was **38%**, with **88 lonely spokes**. The graph's shape said it plainly too: five or six big hubs with leaves bursting out radially — a gathering of *stars*, not a mesh.

This is the "connected but not woven" state. One MOC per folder saves every document from orphanhood, so the linter gives top marks — while the only retrieval path is "its own folder." The multi-path-retrieval mechanism simply isn't running. I'd drawn link-lines over a well-organized drawer and called it a brain. The orphan check is the floor, not the goal.

## What actually works is a write-time cost

To turn stars into a mesh you have to lay links by hand, and that "by hand" is the heart of the system. A link is a cost paid at write-time for a benefit at read-time.

To an engineer this structure is familiar — it's exactly a database index. Add an index and INSERTs get slower, because every write has to update the B-tree. In return, SELECTs get faster. Links in a knowledge graph are the same. The friction of stopping, on every new note, to ask "what does this touch among what already exists" is the index-update cost; the note resurfacing months later from a forgotten context is the retrieval speedup. The fact that you pay up front, at write-time, is exactly why people keep deferring links and let the graph harden into a star.

The atomic-note principle only makes sense on top of this cost structure. Splitting notes small isn't a minimalist aesthetic — it's **so they can be linked independently from elsewhere**. So the test for atomicity isn't length but a one-line question: "Would I ever link to or reuse this concept independently, from somewhere else?" If yes, give it its own note; if it only ever appears in one context, leave it inline. Shattering every sentence is over-indexing — pure maintenance cost, lost cohesion.

## Folders own governance, links own context

So should folders go? Matuschak said prefer association over hierarchy, so is a classification like PARA obsolete? My conclusion is the opposite. Folders and links aren't two competing methods — they're **two systems at different layers**.

Folders (physical classification) own governance: a document's lifecycle — who edits it, when it gets archived, whether it's done. PARA's Projects-vs-Archives split is exactly this lifecycle axis. Links (logical connection) own context, crossing folder boundaries to answer "what is this related to." engram's one-line summary is just that: lay a logical link layer on top of physical classification (Networked PARA).

In practice the accidents happen when you make one do the other's job. Dig folders eight levels deep and classification tries to absorb the connecting that links should do, breeding documents that fit nowhere. Trust only links and abandon classification, and finished projects blur into live work in one graph, erasing the axis you need to decide what's safe to archive. Let folders answer only "where does it live / when does it retire," and links only "what does it touch."

## Neuralizing was as much about removing nodes as adding them

While pulling candidates to weave those 88 spokes, I hit the most unexpected fact: **nearly two-thirds of the spokes were documents that never belonged in the brain at all.** Not knowledge, but *outputs* — artifacts with their own external publishing/delivery workflow. This very blog is the type case: its lifecycle (seed → draft → publish → static site → social) runs *outside* my thinking network. Such documents have almost no reason to touch other knowledge in context — being unwoven is exactly what you'd expect from an output.

Here a decisive distinction emerges. The criterion for separating something out isn't "is it an output?" but **"does it have its own external lifecycle?"** A spec or design doc looks output-like yet stays in the brain — it's where knowledge gets *applied*, the highest-value node. Publications and deliverables, by contrast, belong in a sibling folder outside the brain, so the thinking network doesn't get polluted by outputs.

So the first move that lifted my woven ratio wasn't a link — it was **deletion (separation, precisely)**. Lift the pile of outputs out of the brain, and half the star shape simply vanished. Half of neuralizing is connecting; the other half is **culling the nodes that had no business being on the graph**. The references only ever say "link more"; they almost never say "what should you remove."

## A mechanic's eye: a knowledge graph is an integrity problem

In the stage of weaving the real knowledge that remains, the problem the references say least about surfaces. Every "second brain" rots quietly.

Practitioners have named two failure modes themselves. One is the **collector's fallacy** — mistaking collecting information for knowing it. The other is **over-structuring** — when maintaining the system becomes the goal and actual thinking and output stop. To these I add a purely engineering third: **referential integrity.** A knowledge graph is, in the end, a database — and nobody runs a foreign-key check on it. An orphan node is a row no one references; a broken link is a dangling pointer. Problems a compiler would catch in code, no one catches in a note system.

So engram treats this as **lint**. The cheapest remedy is Nick Milo's MOC: one hub note (a README) per folder linking every document in it dissolves orphans in one stroke. But there's a trap nearly everyone falls into — never write MOC entries in backticks.

```text
# The hub note looks full, yet every document is still an orphan
- `00-overview.md`   ← inline code: the linter strips it, counts as zero links
- `01-threat-model.md`

# Write it like this to be counted as a real inbound link
- [00-overview.md](00-overview.md)
- [01-threat-model.md](01-threat-model.md)
```

The linter strips inline code out of its link count. So however full the README looks as an index, filenames written in backticks count as zero links. A hub that looks fine while connecting nothing — the most common silent integrity failure in this field. One thing became clear: integrity checks like orphans and broken links reduce to rules and can be delegated to a machine, but the judgment of **what to keep and what truly touches what** is a human job. A forced link is noise, not signal. A good tool clears the maintenance cost of the former so a person can spend their budget on the latter.

## Closing

With this ruler and this discipline I gave my brain one pass. I lifted the outputs out and wove the remaining knowledge across folder boundaries. The woven ratio crossed from 38% past 70%, and lonely spokes dropped from 88 to around thirty. Here's the graph after that one pass.

![A knowledge graph whose center has begun to weave into a mesh](graph-after.png)

The stars that only spread radially have started reaching toward each other and forming a mesh in the middle. What matters is that this is not a prettier visualization but more retrieval paths.

"Turning documents into a neural network" is not an empty slogan. Knowledge reachable by many paths really does resurface more often, at more unexpected moments, than knowledge nailed to a single spot. But the references oversell the visualization and undersell the maintenance — and the culling. The firing-brain graph is bait, not result. A pile of documents comes to resemble a brain not when it *looks* like one, but when every thought is reachable from many directions and **stays** that way under entropy. The graph comes for free. Keeping it connected — and lifting out what shouldn't be there — is the real work.
