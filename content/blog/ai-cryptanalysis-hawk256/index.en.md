+++
title = "While We Waited for Quantum Computers, AI Arrived First"
date = 2026-07-29T00:00:00+09:00
draft = false
tags = ["security", "cryptography", "ai", "post-quantum", "cryptanalysis"]
+++

"AI just broke post-quantum cryptography." That headline swept through the security community in late July, following an [announcement from Anthropic](https://www.anthropic.com/research/discovering-cryptographic-weaknesses) that its model had found a key-recovery attack against HAWK-256, a NIST post-quantum signature candidate. The grammar of the reaction was familiar. The old dread — quantum computers will bring down every cipher at once — had returned, with only the subject swapped out for AI.

In a [previous post](https://pelicanlife.dev/en/blog/quantum-threat-symmetric-vs-pki/), I dismantled the quantum panic by classification: cryptography is not one monolith, and quantum computers topple only one side of it. The same tool applies here. Don't stop at the verb 'broke' — separate precisely what broke from what did not.

Let me state the conclusion up front. What broke this time is not the cryptography you use. What broke is the industry's assumption about the speed at which cryptography earns trust.

## What Actually Broke

The substance is two results. First, Claude found a nontrivial automorphism in HAWK's lattice — a symmetry whose possible existence had been theorized but which no one had actually exhibited — and used it to cut the attack cost against HAWK-256, the smallest parameter set, from 2^64 to 2^38 operations. Effective key strength, cut in half. Second, against a reduced 7-round research variant of AES-128 (the full cipher runs 10 rounds), it accelerated the best known attack by a factor of 200 to 800, using a technique that eliminates an entire enumeration step.

Neither result affects any production system today. Anthropic itself stresses this repeatedly in the announcement. HAWK is a candidate under review that has never been deployed anywhere, and the drop to 2^38 applies only to the smallest parameter set — larger variants remain out of practical reach. The AES result targets a reduced-round research version, and the attack remains, in their own words, completely impractical. Judged on this alone, the headline is an exaggeration. And yet the announcement matters. To see why, we first need to clear away the most common misreading.

## It Wasn't a Standard That Broke — It Was an Applicant

"So a NIST post-quantum standard has been broken?" No. The standards NIST finalized in August 2024 are ML-KEM (Kyber), ML-DSA (Dilithium), and SLH-DSA (SPHINCS+), and this attack touches none of them. HAWK is a round-3 candidate in a separate, ongoing competition for additional digital signatures. It is an applicant, not a graduate.

And an applicant failing mid-exam is not a failure of the competition — it is the competition's entire reason to exist. The NIST process has cryptographers worldwide hammer on candidates for years, filtering out whatever shatters before it can become a standard. The structure is that of a clinical trial: a side effect discovered in phase 3 is not a recall of a marketed drug. It means the filter worked before the market was reached.

There is clear precedent. In 2022, SIKE — a KEM candidate that had survived into round 4 — collapsed under a classical attack that ran in about an hour on an ordinary laptop. The same year, Rainbow, a round-3 finalist signature scheme, was broken over a weekend. Both were broken by human cryptanalysts, and no one called it the collapse of the NIST process. The review was doing its job. Only one thing has changed this time: an AI has joined the hands swinging the hammer.

## Two Years of Failure, Sixty Hours of Success

This is the real news, and it deserves precise wording. It is not that "an analysis that used to take two years now takes sixty hours." HAWK had been under public review for more than two years since its submission, and the automorphism in question had been discussed only as a theoretical possibility — in all that time, no one produced the real thing. So this is not a speedup. It is a reversal. A task at which human experts had collectively failed for two years turned into a success in sixty hours.

The mode of execution is worth a close look. The HAWK attack emerged in sixty hours with only occasional, nontechnical direction from a single researcher. The AES work was more extreme: over three days, the model received three substantive prompts, generated roughly a billion tokens, and proceeded almost entirely autonomously. Each project cost about $100,000 in API usage. And the most interesting line in the announcement is elsewhere: verifying the AI's AES result took human researchers several hundred hours, and Anthropic writes plainly that human researchers may become the bottleneck in reviewing and validating AI-generated cryptanalysis. The finding side has become a machine; the bottleneck has moved to the humans.

There is one more asymmetry inside the same announcement worth noticing: the two results differed sharply in how much they cost to verify. The HAWK attack was comparatively easy to check, because a key-recovery attack is an artifact that carries its own verification — run it to the end and see whether the key actually comes out. The AES result offered no such shortcut; humans had to reconstruct the argument itself, and that is where the hundreds of hours went. What determined the size of the verification bottleneck was not the AI's capability but whether the artifact came in a form that could be confirmed by execution. That asymmetry reaches well beyond cryptanalysis into AI collaboration in general — but that is a story for another post.

## Security Is a Survival Record, Not a Certificate

To digest this event properly, one fact has to be faced head-on: the security of modern cryptography is not mathematically proven. The substance of the claim "AES is secure" is a cumulative record of failure — the whole world has hammered on it for a quarter century and no one has broken it yet. The same holds for RSA, and for lattice cryptography. This is why cryptographers never trust a young algorithm right away. The unit of trust is not proof but exposure — time under analysis, and the number of eyes. A survival record.

AI cryptanalysis touches exactly this point. The currency of trust — the survival record — has until now been minted only by the number of human experts and the hours they spend. At sixty hours and $100,000 per finding, the mint runs at a different speed. The clock that governs the hammering has been compressed.

Note that the compression cuts both ways. When the clock runs faster, weak algorithms shatter sooner — but algorithms that survive have withstood more attacks in the same span, and accumulate their survival record faster. The AI hammer is a tool that erodes trust and a tool that tempers it, at once. A company's security does not get worse because more white-hat hackers showed up.

## So Is "Migrate to PQC" Still Good Advice?

The previous post concluded: migrate your public-key surface to PQC. But the migration targets are young, their survival records shallow — and AI digs into shallowness fast. So has the credibility of the finalized PQC standards been damaged? Should we wait for the next round of standards?

The answer comes in three parts. First, this attack does not transfer. What it exploited is a symmetry peculiar to HAWK's lattice; the finalized standards rest on a different mathematical problem (Module-LWE). The accurate statement is not "lattice cryptography is now at risk" but "HAWK's particular design was weak." The real lesson of the HAWK case lies elsewhere: even when the underlying problem is solid, a scheme's own design choices can be weak — and that is usually where things break.

Second, because of the two-way compression above, the finalized standards are not losing credibility — their trial is intensifying. ML-KEM is a survivor of more than eight years of worldwide attack since the competition began in 2016, and it now accumulates its record under AI fire as well. As long as it survives, its trust grows faster than it used to.

Third, the option of waiting does not actually exist. Whatever you run while waiting for the next standard is RSA and ECC — and their collapse before Shor's algorithm is not a possibility but a schedule. Recall Harvest Now, Decrypt Later from the previous post: for long-lived data, the exposure is already in progress. The real choice is not "under-vetted PQC versus a safe status quo" but "PQC versus public-key cryptography with a confirmed death sentence." So the practical answer remains hybrid: run classical public-key and PQC side by side, and if the PQC half ever breaks, classical security still stands.

## Not "When It Arrives" but "How Long It Takes"

The debate over quantum commercialization timelines resolves in the same frame. A quantum computer that actually breaks RSA-2048 needs thousands of error-corrected logical qubits — millions of physical ones — and forecasts cluster around the mid-to-late 2030s. But building a defense plan on that forecast is aiming at the wrong target. The question is not "when is Q-Day" but "how long does migration take."

Cryptographic transitions in large systems have historically taken on the order of a decade — 3DES to AES, the retirement of SHA-1. The basic arithmetic of this game is Mosca's inequality: if your data's required secrecy lifetime plus your migration time exceeds the time remaining until Q-Day, you are already late. This is why national responses run on deadlines, not forecasts. The NSA's CNSA 2.0 targets full transition by 2033; NIST has marked RSA and ECC deprecated after 2030 and disallowed after 2035; Korea's national cryptography transition plan also aims at 2035. The working order is equally fixed: inventory first — know where every cipher lives — then hybrid deployment, then crypto agility: an architecture that can swap out any algorithm.

## Closing

Back to the headline. "AI broke post-quantum cryptography." We can now rewrite it accurately: AI did not break deployed cryptography — inside the proving ground that filters algorithms before deployment, it found in sixty hours a crack that humans had missed for two years. It did not pick the lock. It upgraded the hammer in the lock-testing facility.

In the era of the faster hammer, preparedness cannot mean faith in any particular algorithm. It means building, in advance, on the premise that any algorithm may eventually shatter — a structure where the broken part can be swapped out the moment it breaks. Trust placed not in algorithms but in replaceability: that is what preparation actually is. To borrow the earlier post's sentence: vague dread loses its force, once again, before precise classification. What collapsed was not the cryptography but the headline — and what remains is to run the migration sequence on a clock that just got faster.
