+++
title = "Proving Provenance Doesn't Stop Malicious Code"
date = 2026-06-18T00:00:00+09:00
draft = false
tags = ["security", "supply-chain", "npm", "software-integrity", "devsecops"]
+++

Lately the security world abroad has been busy over a single incident. On May 19, 2026, more than 300 malicious versions were published across 323 packages on the npm registry in the span of 22 minutes, reportedly. The key point is that no human did this. There was no attacker sitting at a keyboard infecting packages one by one. The code itself stole maintainer tokens, used those tokens to replicate itself into other packages, and stole more tokens from there — all without human intervention, the reports say. A self-replicating worm called "Shai-Hulud" is said to have spread through the npm ecosystem this way.

I'll be honest: I'm not someone deeply familiar with the inner workings of the npm ecosystem. This piece is closer to a record of following along with analyses from researchers abroad, working through concepts I was encountering for the first time. But as I followed the unfamiliar material, I noticed that multiple analyses converged on one point. The integrity controls we had built with so much care to protect the supply chain barely worked against this worm. Signatures, provenance attestations, build verification — none of them stopped it, reportedly. I wanted to follow that reasoning through.

## 22 Minutes, an Intrusion Without a Human

Traditional supply chain attacks relied on human hands, the reports say. An attacker takes over the maintainer account of a popular package and crafts and publishes a malicious version directly. A single attack ended at one package, or at most a few. The human was the bottleneck.

Shai-Hulud is described as a form that removes that bottleneck. The moment an infected package is installed, the malicious code scrapes npm tokens, CI/CD secrets, and cloud credentials from that environment. Then, using the stolen npm token, it replicates itself as a new version into other packages that the maintainer has publish rights to. When someone installs one of those packages, the same thing happens again. The attack is the propagation, and the propagation is the attack. A self-replicating loop filled the place the human used to occupy.

The name comes from the giant sandworm in Frank Herbert's novel Dune, reportedly — a creature that swims through the sand and breeds on its own. It fits this code, swimming through the open-source dependency graph, eerily well. The scale, too, looks like a natural consequence of that structure. timeago.js, with 1.5 million weekly downloads, and the @antv namespace widely used for chart and graph visualization were infected at once, and the stolen credentials were reportedly dumped straight into more than 2,200 public GitHub repositories. The number 22 minutes speaks not to the attacker's diligence, but to the speed of an attack with the human removed.

## The Worm Flows Through the Plumbing of Trust

The most striking passage as I read was the explanation that this worm doesn't break in through a vulnerability. It reportedly uses no buffer overflow, no injection, no privilege-escalation bug. Instead it abuses one thing the npm ecosystem must trust in order to function normally: the maintainer's publish rights.

npm's trust model is simple, by the accounts I read. Whoever holds a token with the right to publish a package is the legitimate owner of that package. If the token is valid, the registry asks nothing more. When you think about it, this assumption is essential for the ecosystem to run. You can't have humans vet millions of packages one at a time, so it delegates with the rule "trust whoever holds the rights."

To borrow the researchers' explanation, Shai-Hulud hijacks exactly that delegation. The instant it steals a token, the worm becomes, from the registry's point of view, a perfectly legitimate maintainer. The analogy that resonated with me: the intruder didn't climb the wall — they copied the owner's key and walked in through the front door. So no lock guarding the entrance can stop them. They come in fully entitled to open every lock the normal way.

## Malicious Code That Passed SLSA Verification

The point I chewed on most in this incident lies elsewhere. Some of the malicious packages in this wave were reportedly published carrying valid SLSA Build Level 3 provenance attestations — the very control held up as the model answer for supply chain security. Provenance itself was an unfamiliar concept to me, so I had to start by working out what exactly it guarantees.

Pulling the material together, here's what I gathered. Sigstore-based provenance cryptographically proves "which build pipeline produced this package," reportedly. A GitHub Actions workflow uses OIDC to obtain a short-lived token, builds the package, and attaches a signed record of its origin. It was introduced to remove long-lived tokens from workflows — clearly a step forward, by all accounts.

But what multiple analyses point to in common is the scope of the question that proof answers. Provenance only proves "who made it," not "whether the maker meant well." When malicious code runs inside a legitimate pipeline, that pipeline honestly builds the malicious code and honestly signs its origin. To borrow one analysis's phrasing, a valid Sigstore attestation confirms which pipeline made a package — not whether that pipeline was compromised. It means a package whose origin is perfectly genuine and whose contents are perfectly malicious is possible. Many writeups agreed that this is the blind spot of the very concept of integrity verification.

## Verification Asks About Origin, Not Contents

What's interesting is that this blind spot isn't unique to Shai-Hulud. As I followed along, it looked like a structural limit underlying the entire act of integrity verification. Signatures, checksums, and provenance each answer a different question, but none of them answers "is this code safe?"

Here's how it reads, laid out. A checksum asks "was it altered in transit?" A signature asks "was it made by the owner of the key I know?" Provenance asks "did it pass through a pipeline I trust?" All three questions are about "origin and path," not about "the intent of the contents." So malicious code signed with a legitimate key, a backdoor built by a trusted pipeline, passes every one of these checks. We confirm whether the lock is genuine, but never ask what the person who legitimately opened that lock carried in.

I was reminded of an incident with a similar shape. AMD's auto-updater verified update files with only a CRC-32 checksum, without a cryptographic signature, leaving it exposed to a man-in-the-middle attack. The lesson taken at the time was "a checksum isn't enough, use a signature." Shai-Hulud seems to repeat the same story one rung up that ladder. A signature isn't enough either, nor is provenance. No matter how much you strengthen the kind of verification, as long as verification only asks about origin, malice that came in through a legitimate path always passes.

## The preinstall Hook: Installing Is Already Executing

How the worm executes "the moment it's installed" was another unfamiliar part I looked into separately. The secret reportedly lies in npm's lifecycle scripts. The preinstall hook defined in package.json runs before the package installation even completes. The act of downloading code and unpacking it to disk is not separated from the act of running it right away.

```json
{
  "scripts": {
    "preinstall": "bun run index.js"
  }
}
```

This one line makes `npm install` an arbitrary code execution, reportedly. Shai-Hulud ran its payload on the Bun runtime, and if Bun wasn't present in the build environment, it would even fetch it directly during installation, the analysis says.

```bash
# payload bootstrap when Bun is absent
curl -fsSL https://bun.sh/install | bash
```

After reading this, my everyday `npm install` looked different. The instant a developer types the command just to add one dependency, code they never trusted can walk off with their credentials. We think of a package as something we "download now and review later," but in the world of lifecycle hooks, installation was already execution.

## The Line of Defense Is Blast Radius, Not Verification

So what should be done? What resonated across the various recommendations I read was a shift in framing. You can't stop this worm by verifying "is this package genuine?" more strictly, because it passes every check legitimately. So the recommendations put their weight not on the intrusion itself, but on shrinking the range it can spread to once an intrusion succeeds. It read as moving the center of gravity of security from verification to blast-radius control.

The concrete recommendations mostly converge like this. In CI environments, make `npm install --ignore-scripts` the default. Blocking lifecycle scripts like preinstall and postinstall cuts the very loop where installation becomes execution, reportedly. Restricting the build environment's outbound network to trusted domains only narrows the path for exfiltrating stolen credentials. Issue short-lived, least-privilege tokens instead of long-lived, broad ones. The shorter a stolen token's life and the narrower its scope, the fewer packages it can replicate into. What struck me was the explanation that the most lethal thing for a self-replicating worm is taking away its "permission to cross to the next host."

What these measures have in common is that not one of them tries to "judge whether something is malicious." Instead, on the premise that malicious code did get in, they narrow what it can do. It isn't a game of blocking the intrusion, but a game of containing its consequences.

## Closing

What Shai-Hulud revealed, I think, isn't some bug in npm, but the boundary of the very concept of integrity verification. Signatures and provenance are still necessary and still valid. It's just that they vouch for "origin and path," not for "the intent of the contents." Against malice that opened the front door with a legitimate key, no amount of refinement on the entrance lock helps.

I only read along through material in an unfamiliar field, but in the process I came to revisit the boundary of integrity verification I had taken for granted. When I wrote up quantum computing earlier, I put it as "what collapses is not the lock but the ritual of handing over the key" — and this worm, too, ultimately targets not the code but our delegation of trust in code. They turned out to be alike in that. When a threat burrows into the structure of trust, defense has to move beyond verification toward the design of blast radius. That's what I took away this time.

I intend to carry this perspective into the projects I work on. Alongside the work of verifying "is this dependency genuine?", the work of designing "if it turns out to be false, how far can the damage be contained?" That admitting what you cannot block is where designing what you can contain begins — I came to feel that a little more concretely by following this incident.
</content>
