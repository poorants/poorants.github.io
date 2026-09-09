+++
title = "When the Brain Grew, the Problem Wasn't Search. It Was Tokens."
date = 2026-09-09T00:00:00+09:00
draft = false
tags = ["knowledge-management", "postgresql", "full-text-search", "ai-agent", "second-brain"]
+++

I was watching five whole documents get poured into a context window to answer a single question. This was the path an agent took through our team's shared brain: pull search terms out of the question, grep the markdown files, open the top five by match count, and read until it hits the answer. I modeled that path mechanically and measured it. An average of 9,391 tokens per question. The answer was usually in there. The problem wasn't whether the answer existed — it was that pulling out one line cost five documents' worth of reading.

In [my last post](https://pelicanlife.dev/en/blog/documents-as-neural-network/) I argued that a pile of documents resembles a brain not when it looks like one, but when every thought can be reached from several directions and that state survives entropy. The graph comes for free; keeping it connected is the real work. In the two months since writing that, a different problem arrived first. Scale.

The brain went from 63 documents to 242 in two months. The document count quadrupled, and so did the cost of working with it. When a system whose entire purpose is accumulating knowledge gets harder to use the more it accumulates, that isn't growing pains. It's a design defect.

## The cost scaled with the number of documents

In a file-based brain, all three core operations were O(all documents).

**Finding** is what I just described: grep filenames and bodies, then read candidates whole. **Linking** was worse. With no link graph stored anywhere, the linter reparsed every document to rebuild the graph from scratch on every run, and picking weave candidates was string scanning. **Preventing overlap** — the rule that says 'if a document already covers this topic, update it instead of writing a new one' — had grep as its only enforcement mechanism, so any difference in phrasing defeated it. That rule was being followed maybe half the time.

At 242 documents this still holds. At 1,000 all three collapse. And the cheapest moment to fix something like this is before it collapses.

## Set the baseline in your opponent's favor

Before starting, I wanted to nail down the bar to clear. One criterion: is this better than grep? I wrote 31 questions, mixing exact-identifier lookups with descriptive ones, and **hand-picked the search terms to favor grep.** You have only earned something if you beat a baseline that was given every advantage.

It came back at 90% recall@5. Far higher than I expected. I backed off for a moment, then went digging through the failures and found out what that 90% actually was. The search terms I had handed it were the titles of the answer documents. For the question 'how much data fits in a single row,' I supplied `row`, `length`, `limit` — and the answer document was titled 'Row Length Limits.' I had leaked the answer into the baseline.

So I built a second baseline where the terms are extracted mechanically from the question instead of chosen by a human. Recall dropped to 55% and tokens jumped to 27,197. A real agent lives somewhere between those two.

The lesson generalizes past this project. Tilt the baseline toward yourself and winning proves nothing; tilt it toward your opponent and you look unbeatable. Tilting toward the opponent is correct — but you have to **keep digging into why it is winning.** Whether a number reflects skill or leakage is usually hiding in the successes, not the failures.

## The fight was about the unit of return, not recall

I put chunking and a lexical index on Postgres and measured again with the same ruler.

| | grep ①<br>hand-picked terms | grep ②<br>extracted from question | lexical index |
|---|---:|---:|---:|
| recall@5 | 90% *(answer leaked)* | 55% | 77% |
| tokens per question | 9,391 | 27,197 | **1,692** |
| search latency | — | — | 12ms |

On recall alone, the index loses to the leaky baseline. The fight was decided on a different row of the same table. 1,692 tokens. Sixteen times cheaper.

The reason is the unit of return, not the ranking. grep returns files, so when you need one paragraph out of a 3,000-word document you get 3,000 words. The index returns a chunk plus the heading path locating it inside its document. The agent receives a paragraph and its coordinates instead of opening a document, and only opens the document when it genuinely needs to.

A habit broke here: measuring search quality by recall alone. For search a human uses, over-returning is nearly free — you skim and discard. For search an agent uses, everything returned gets loaded into the context, and everything loaded is paid for. That calls for a second metric. Not *did it find the answer*, but **what did finding it cost.**

## Removing embeddings made everything better

Naturally I had added vector search. How else do you get past vocabulary mismatch without semantic retrieval?

I switched the channel off entirely and re-measured. The results were identical. Recall held at 77%, and **the set of failing questions was the same set.** Cosine distances to the correct documents clustered between 0.49 and 0.84 — the model could not discriminate among Korean technical documents at all. Vocabulary mismatch is a wall when the query is English and the corpus is Korean, not when Korean documents are searched in Korean. On top of that, this brain has unusually descriptive titles and filenames, a side effect of the linking discipline. Lexical search was already collecting the dividend of that discipline.

Taking it out improved everything else. A full index went from 594 seconds to 1.9. Search latency went from 83ms to 12ms. Resident memory went from 300MB to zero. No vector extension, no embedding model. Stock PostgreSQL was enough.

There is no Korean text-search extension either. The indexer builds lexemes itself and bypasses the parser.

```sql
-- The default parser splits identifiers on underscores,
-- so an exact-symbol query never lands on the document that defines it.
SELECT to_tsvector('simple', 'pthread_mutex_lock');
--  'lock':3 'mutex':2 'pthread':1

-- The indexer emits lexemes itself: identifiers stay whole,
-- Korean is expanded into syllable bigrams. No parser, no extension.
SELECT array_to_tsvector(ARRAY['pthread_mutex_lock', '잠금', '금해', '해제']);
```

And removing it took a piece of complexity with it. If a full reindex takes 1.9 seconds, incremental update logic is unnecessary — just rebuild the whole thing on every write. I reached a state that needs no optimization not by optimizing, but by **deleting.**

## Once the source of truth moves in, "rebuild" means deleting knowledge

Up to this point the index was derived data. The source of truth was still markdown in git, which is why the schema opened with this line: 'the index is derived, so rebuild it wholesale.' If the database vanished, one push restored it. A safe sentence.

The moment the source of truth moves into the database, that sentence becomes a dangerous lie. DROP followed by CREATE is no longer an index rebuild; it is knowledge deletion. So I split the layers. Body text and revision history are canonical; chunks, the inverted index, and links are derived and can be rebuilt from bodies at any time. I stripped DROP out of the schema and made the rederive path touch derived data only. The migration endpoint was demoted from wholesale rebuild to upsert-only — documents absent from the payload are left alone.

Work that git had been doing for free now has to be done deliberately. Every write stores the previous body as a revision, and deletes are soft so they can be undone. From this point backups are not optional, they are a precondition: a daily dump pushed to external storage, and a restore you have actually performed. Otherwise you don't get to call it a backup.

I stumbled here once. The service could export documents back out as markdown — a 'mirror' — and that mirror quietly started reading as a backup. A mirror is not a backup. It cannot carry revisions, so who changed what and why is not recoverable, and the path back in had been deliberately blocked after an earlier incident. **You cannot call something a backup when it has no restore path.** I retired the mirror, and what surfaced in the process stung more: mirror generation had been failing every hour, and nobody noticed for three days. A copy no one has ever restored from can sit there dead without showing a symptom.

Links only started behaving like database rows at this point too. In a file brain, links pointed at names and paths because a file has no other identity. A database document has an immutable key. Move a document and the old address survives as an alias, so links other people wrote keep landing. In a file brain that same move meant editing links in 200 places or leaving them broken. It also exposed an old bug: soft-deleted documents were still emitting edges into the graph, inflating the broken-link count to 411. The real number was 14.

## People and agents hit the same ranking

The last step was wrapping the store in an MCP server and opening it to the whole team. Agents get six verbs. Search; open one document with its links and backlinks; read the revision history; check integrity; write; move. There is no delete — archiving replaces it.

One thing was fixed from the start. The search box a person types into and the search tool an agent calls **hit the same path.** Two rankings mean the order a person sees and the order an agent sees diverge, and from that point on they are not using the same brain.

Two weeks after opening it up, the brain holds 559 documents across eight repositories. What took two months to reach 242 doubled again in two weeks. The fastest-growing folder was, predictably, troubleshooting. A probe that reports empty results when it hasn't actually failed; a race that only reproduces after a reboot; a push rejection caused by a shadowed deploy key. Every one of them costs the first person half a day and the second person nothing — if the second person can find it.

The nature of the efficiency gain is unglamorous. It is exactly one thing: **not investigating the same question twice.** An incident that burned three days at the next desk yesterday now surfaces as a single paragraph in my session in 12ms. What actually consumes time in issue handling is not the fixing, it is confirming whether someone has hit this before — and back when that confirmation was grep, confirming cost more than investigating from scratch. So nobody confirmed.

## Closing

My last post concluded with maintenance. I wrote that keeping the graph connected is the real work, and I have no intention of retracting that sentence. But there is one thing I have learned since. **When retrieval is expensive, the reason to maintain evaporates.** Who is going to hand-weave a graph that nobody draws from? A link is a write-time cost paid for a read-time benefit, and when the read-time benefit gets eaten by tokens, that trade no longer clears.

Looking back, most of the work in this project was subtraction. I removed the embeddings, removed the search extension, removed the incremental update logic, removed a mirror that was pretending to be a backup. Three things stayed: the canonical text, its history, and one ranking.

The brain now costs the same per question regardless of how many documents it holds. Going from 559 to 1,000 will not change what an agent pays for one answer — still a few paragraphs' worth. In my last post I wrote that the graph comes for free. I would add a line to that now. The graph is free, but **pulling anything out of it is not, and making that price a constant is the design problem of a knowledge system.** A system that got worse as documents accumulated now gets better as they do. What changed was not the discipline. It was one cost structure.
