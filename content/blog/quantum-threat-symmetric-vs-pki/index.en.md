+++
title = "Quantum Computers Won't Crack Your Encrypted Database"
date = 2026-06-13T00:00:00+09:00
draft = false
tags = ["security", "cryptography", "quantum", "pki", "post-quantum"]
+++

"Once quantum computers arrive, won't your database encryption solution be useless too?" When you tell people you build security products, this is the question you hear most often these days. A vague dread sits behind it. The moment the word *quantum* shows up, an apocalyptic image follows — every lock in the world springing open at once.

There is one decisive misconception buried in that fear: it treats "encryption" as a single block. In reality, encryption splits into two camps with entirely different characters, and a quantum computer topples only one of them. The side that falls is not the encryption that locks data itself, but the encryption that establishes trust when data is exchanged. Fail to draw that line, and you will forever misjudge the size of the threat.

## Encryption Is Not One Block

Cryptographic systems divide into two broad kinds. One is symmetric-key encryption — block ciphers. AES, ARIA, and SEED belong here. Their job is to lock the data itself. Database column encryption, disk encryption, file encryption — every task that keeps data unreadable while it sits at rest is this camp's responsibility. The key that locks and the key that unlocks are one and the same secret key, and everything hinges on how safely you store it.

The other is public-key encryption. RSA, ECC, and Diffie-Hellman belong here. Their job is not to lock data but to "exchange keys safely" and "prove the other party is genuine." TLS session-key exchange, certificates, digital signatures, code signing — all of it is public-key territory. The asymmetry that the locking key (public key) and the unlocking key (private key) differ is the heart of this camp.

When you talk about quantum computers, skipping this distinction tangles the whole discussion. The two camps meet entirely different fates in the face of the quantum threat. One straightens its collar and moves on; the other collapses at the level of its design principle.

## Grover Only Picks the Lock Faster

Start with the symmetric camp. The weapon a quantum computer brings against AES is Grover's algorithm. The name sounds grand, but what Grover does is essentially make brute force a little faster. And it shrinks the search space only by a square root — in plain terms, it cuts the effective strength of the cipher in half.

AES-128 weakens to roughly the 64-bit level against a quantum computer. But AES-256 remains at the 128-bit level. 128 bits is a wall that cannot be broken in any realistic span of time, now or in the foreseeable future. The conclusion is simple. Double the key length — that is, use AES-256 — and the original security is restored even against a quantum computer. You don't even need to change the algorithm.

This is called a *quantitative* threat. The attack gets faster, but the defender can keep pace at the same ratio just by turning the dial of key length. When a thief who picks locks faster shows up, doubling the number of pins on the lock settles it. The rules of the game themselves do not change.

## Shor Steals the Lock's Blueprint

The public-key camp is an entirely different story. To understand the difference, you first have to ask why public-key crypto was ever safe. Public-key encryption is built on a "mathematical problem that is easy one way but practically impossible in reverse." Take RSA: multiplying two large primes is instant. But recovering the original two primes from that product alone — factoring — takes a conventional computer a span on the order of the age of the universe. ECC and Diffie-Hellman lean on the discrete logarithm, a problem of similar character.

By analogy: anyone can click the lock shut (the public key), but the key that opens it (the private key) can only be made by someone who knows the secret. The single assumption that you cannot work backward from a public key to a private key is what all of the internet's trust rests upon.

Shor's algorithm breaks exactly that assumption. On a quantum computer, Shor solves factoring and discrete logarithms by a shortcut. It becomes possible to compute the private key in reverse from the public key alone. This is not picking the lock faster — it is obtaining the lock's entire blueprint. That is why lengthening the key does not help. Swap RSA-2048 for RSA-4096 and it merely takes Shor a little longer; it falls the same way. This is *qualitative* collapse.

## A Quantum Computer Is Not a Universal Codebreaker

A natural question arises here. If a quantum computer is so powerful, why does it break RSA but not AES? The answer is that a quantum computer is not a universal codebreaker but a machine specialized for problems with a specific structure.

A conventional computer's bit is either 0 or 1, and it tries candidate answers one at a time in sequence. A qubit, by contrast, can hold 0 and 1 superposed at once. People often misread this as "computing every case simultaneously," but that is not quite right. A quantum computer engineers the interference between qubits with precision so that, only for problems with a certain mathematical structure — periodicity in particular — it carves out a shortcut to the answer.

Factoring happens to carry that structure of periodicity. Shor's algorithm digs into that structure and reaches the answer. AES and other block ciphers, on the other hand, are products deliberately stripped of such mathematical regularity from the design stage. With no structure to exploit, even a quantum computer is left with brute force — that is, Grover. Here lies the decisive difference that split the fates of the two camps. Public-key crypto stood on a fragile mathematical elegance; symmetric crypto survives the quantum era precisely because it threw that elegance away on purpose.

## Why It Is Dangerous "Starting Now"

There is not yet a quantum computer large enough to actually break RSA-2048. The day commonly called "Q-Day" has not come. So why is the security industry already busy? Because of an attack scenario called "Harvest Now, Decrypt Later."

The principle is simple, and that is what makes it more chilling. Right now, you collect the TLS-encrypted traffic crossing the network and store it cheaply, as is. Then, on the day a sufficiently large quantum computer is completed, you decrypt that stored traffic — because the public key used in the key exchange breaks that day. In the end, any "data that must stay secret ten years from now" is already exposed to risk starting today. The longer a piece of data must live — medical records, financial transactions, state secrets — the less room there is to defer the transition. The threat is in the future tense, but the exposure is in the present.

## What NIST Standardized Is the Answer

The conclusion of this entire discussion is written, surprisingly, in a very clear place: the first three post-quantum cryptography (PQC) standards NIST finalized in August 2024. FIPS 203's ML-KEM (Kyber) replaces key exchange; FIPS 204's ML-DSA (Dilithium) and FIPS 205's SLH-DSA (SPHINCS+) replace digital signatures.

Look at what the three standards have in common. They all replace the role that public-key crypto held. There is no standard on that list to replace symmetric crypto — that is, AES. As cryptographers worldwide spent years designing the next-generation standards, what they chose to swap out and what they left in place is itself a map of the threat. The dangerous ground is public-key crypto; symmetric crypto holds its place by simply growing its key length. The very direction of standardization proves this article's argument for it.

## Closing

Return to the opening question. "Once quantum computers arrive, won't database encryption be useless too?" Now it can be answered precisely. The ciphertext you stored in the database with AES-256 remains safe even in the quantum era — provided you manage the keys properly. What actually falls is the TLS session-key exchange when that data crosses the network, the code signing that vouched for your solution's integrity, the certificate that proved an identity. It is not the locked vault that shatters, but the ritual of handing over the vault's key, and the certificate that vouched the vault was genuine.

So our task is not to be overwhelmed by fear but to read the terrain precisely. Audit key lengths in the symmetric domain; build a migration roadmap to PQC in the public-key domain. A hybrid approach that applies legacy public-key and PQC side by side is the realistic first step for now. Vague doom always loses its power in the face of accurate classification. A quantum computer is not a master key that opens every lock — it is a machine that eavesdrops on one specific ritual. Proper preparation begins with knowing that difference.
