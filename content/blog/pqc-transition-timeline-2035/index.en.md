+++
title = "2035 Is Closer Than It Looks: Reading the Post-Quantum Transition Timeline"
date = 2026-11-08T00:00:00+09:00
draft = false
tags = ["security", "cryptography", "post-quantum", "compliance", "tls"]
description = "NIST IR 8547, the US executive order, EU and UK roadmaps, Korea's KCMVP schedule and amended Quantum Act: scattered PQC deadlines on one timeline."
+++

The one-page notice that Korea's National Intelligence Service (NIS) posted on September 1 contains a single table. The NIS runs Korea's cryptographic module validation program (KCMVP), and the key encapsulation (KEM) column of that table reads: "validation targets selected January 2027 (planned), validation begins January 2028, mandatory inclusion January 2029." The footnote below the table is two lines long. When validation begins, a "hybrid scheme" that combines the new algorithm with a public-key algorithm already on the validation list must be implemented, and the mandate covers "every cryptographic module that includes public-key cryptographic functions."

Similar documents arrived one after another the same autumn. On October 27, NIST published the final version of IR 8547, its report on the transition to post-quantum cryptography (PQC). On November 20, an amendment to Korea's Quantum Act (the Act on the Promotion of Quantum Science, Technology and Industry) takes effect, adding a new definition of "quantum security." Taken one at a time, each is just an agency notice. Put the dates on one line, though, and the picture changes. 2035 is a distant target, but the interim deadlines in front of it already fall within the next four to five years.

This post gathers those dates onto a single page. It traces what is mandatory and what is only recommended, whether key exchange or signatures come first, and why nearly every agency uses the same word: "hybrid."

## The Threat Model Is Already Drawn

In [my June post](/en/blog/quantum-threat-symmetric-vs-pki/) I argued that what quantum computers break is public-key cryptography, not symmetric cryptography. Ciphertext stored under AES holds up as long as the key is long enough, but TLS key exchange and certificate and code signing collapse at the level of their design principles in the face of Shor's algorithm. And because of "Harvest Now, Decrypt Later" attacks, which collect traffic today to decrypt it later, data that must stay secret for a long time is already exposed today.

If that post covered "what is at risk," this one covers "what has to change, and by when." That question is answered by a schedule, not by technology. With FIPS 203 (ML-KEM), FIPS 204 (ML-DSA) and FIPS 205 (SLH-DSA) finalized by NIST in August 2024, the standards were in place. What governments have produced in the two years since is not new algorithms but dates.

## United States: Recommended Dates Became Deadlines

The starting point is IR 8547. The final version groups quantum-vulnerable public-key algorithms (RSA, ECDSA, EdDSA, finite-field and elliptic-curve Diffie-Hellman, MQV) as **deprecated after 2030 and disallowed after 2035**. SP 800-57 had originally planned to disallow 112-bit-strength public keys on January 1, 2031. The final version drops that plan and applies the same schedule regardless of strength. As the default replacement for key exchange, it recommends ML-KEM-768.

It was the executive branch that gave the dates teeth. Executive Order 14412, signed June 22, 2026, and OMB memo M-26-15, which implements it, set deadlines for federal high-value assets and high-impact systems: PQC key establishment by **December 31, 2030**, and PQC signatures by **December 31, 2031**. Under Executive Order 14306 and the same memo, agencies must also support TLS 1.3 by January 2, 2030. The overall 2035 target set by NSM-10 stands.

What to read here is the order. **Key exchange comes a year before signatures.** Breaking a signature only matters at the moment a forgery takes place, whereas with key exchange, traffic recorded today can be decrypted ten years from now. The HNDL threat is reflected directly in the schedule. The NIST report likewise states that systems requiring long-term confidentiality should transition first.

## Europe and the UK: The Same 2035, Different Waypoints

In June 2025 the EU published the NIS Cooperation Group's "Coordinated Implementation Roadmap." It sets three deadlines. By the end of 2026, every member state should have taken first steps and have a national transition roadmap, and should begin planning and piloting for high- and medium-risk use cases. By the end of 2030, the transition of high-risk use cases should be complete, with quantum-safe software and firmware upgrades enabled by default. By the end of 2035, medium-risk use cases should be finished, and low-risk use cases as far as feasible.

The UK NCSC set out phased deadlines in March 2025. By 2028, define goals, carry out a full discovery of services and infrastructure that depend on cryptography, and draw up an initial plan. By 2031, execute the highest-priority migrations and complete the plan. By 2035, finish migrating all systems, services and products.

All three regions end at 2035. The difference lies in the waypoints. The US pulled key exchange for high-risk systems forward to 2030; the EU bundled all high-risk use cases into 2030. The UK made 2028 the deadline for "discovery." The wording differs, but the message is the same: **by around 2030, the most important things should actually have changed.**

## Korea: Algorithms, a Validation Schedule, and Law

Korea has moved along three tracks. The first is algorithms. According to KISA (the Korea Internet & Security Agency), the Korean Post-Quantum Cryptography competition (KpqC) made its final selection of four algorithms in January 2025: NTRU+, SMAUG-T, HAETAE and AIMer. On the policy side, a national PQC transition master plan came out in July 2023, followed in September 2025 by a comprehensive national plan for transitioning to a quantum-resistant cryptosystem. Press coverage at the time of the master plan reported the goal as converting the national cryptosystem by 2035. Since 2025, sector-by-sector pilot transition projects have been running.

The second track is the validation schedule, and it is the one that touches practitioners most directly. The NIS notice from the introduction lists candidate KCMVP validation targets: three KEMs (ML-KEM, NTRU+, SMAUG-T) and four digital signature schemes (AIMer, HAETAE, ML-DSA, SLH-DSA). International standards and the results of the domestic competition sit side by side in one table. KEMs go first: selection in January 2027 (planned), validation beginning January 2028, and mandatory inclusion in January 2029. Signatures are to be selected in January 2028 (planned), with validation and the mandate following one and two years after selection. Here too, key exchange comes first.

The third track is law. The Act on the Promotion of Quantum Science, Technology and Industry took effect on November 1, 2024. The version amended in May 2026, which takes effect on November 20, adds a definition of "quantum security": technologies, systems and procedures that respond to security threats arising from advances in quantum computing. The new Article 18-2 directs the government to prepare measures for building quantum-security frameworks for critical information and communications infrastructure. It also allows the government to require public institutions and infrastructure operators to draw up and carry out implementation plans, and has the Ministry of Science and ICT develop technical guidelines in consultation with the NIS. The law names no algorithms. Even so, the question of "who has to make a plan" now has a legal basis.

## Why Hybrid Is the Default for the Transition

The footnote in the NIS notice, a section of the NIST report and browsers' default settings all converge on the same word: hybrid. A classical key exchange (for example X25519) and a PQC key encapsulation (ML-KEM) are performed together, and the two shared secrets are concatenated to derive the session key. As long as either one is secure, the session key is secure.

This construction became the default because it avoids two risks at once. One is the risk that a quantum computer breaks the classical algorithm. The other is the risk of flaws turning up in new algorithms, or their implementations, that still have little field experience. IR 8547 describes hybrid as exactly this kind of hedge, while also noting its costs: added implementation complexity, and the fact that it is usually a temporary measure. It also makes room for hybrid in the rules. It permits combining a classical shared secret and a PQC shared secret using the SP 800-56C combination method (Z‖T), and states explicitly that one of the two may be a non-approved algorithm. It also says FIPS 140 validation will accept hybrid key-establishment modes and dual signatures.

The web has already moved to this construction. In September 2024 Chrome announced it would retire its experimental Kyber support and, starting with Chrome 131, switch to a hybrid of X25519 and ML-KEM-768 (TLS codepoint 0x11EC). In April 2025, OpenSSL's 3.5 LTS release shipped ML-KEM, ML-DSA and SLH-DSA built in and changed the default key shares to X25519MLKEM768 and X25519. The share of human traffic that Cloudflare measured as post-quantum encrypted rose from 29% in early 2025 to 52% in early December. In August 2026 this hybrid group was standardized as RFC 10024.

Hybrid has two faces, however. Hybrid key exchange is already running, but on the signature side the paths still diverge. There is the composite approach, which binds two algorithms into a single certificate, and the dual approach, which attaches two signatures. Key exchange happens fresh on every connection, so a software update changes it; signatures require the certificate ecosystem and every verifying party to move together. I suspect this difference is part of why the US schedule gives signatures an extra year.

## The Timeline on One Page

| Region | What | When | Nature |
|---|---|---|---|
| US NIST | FIPS 203, 204, 205 finalized | 2024-08 | Standard |
| Korea | Act on the Promotion of Quantum Science, Technology and Industry takes effect | 2024-11-01 | Law |
| Korea KpqC | NTRU+, SMAUG-T, HAETAE, AIMer selected | 2025-01 | Domestic competition |
| US NIST | HQC selected as backup KEM to ML-KEM | 2025-03 | Standardization in progress |
| UK NCSC | Phased migration deadlines announced | 2025-03 | Guidance |
| OpenSSL | 3.5 LTS, default key share switched to hybrid | 2025-04 | Implementation |
| EU | Coordinated roadmap published | 2025-06 | Guidance (member-state coordination) |
| Korea NIS | KCMVP PQC candidate targets and schedule announced | 2026-09-01 | Validation program |
| US NIST | IR 8547 final | 2026-10-27 | Federal guidance |
| Korea | Amended Quantum Act (quantum security definition, infrastructure measures) takes effect | 2026-11-20 | Law |
| EU | National roadmaps and first steps | 2026-12-31 | Guidance |
| Korea NIS | KEM validation targets selected / signatures selected | 2027-01 / 2028-01 (planned) | Validation program |
| UK NCSC | Goals, full discovery, initial plan | 2028 | Guidance |
| Korea NIS | KEM validation begins → mandatory inclusion | 2028-01 → 2029-01 | Mandatory (crypto modules) |
| US | Federal agencies support TLS 1.3 | 2030-01-02 | Mandatory (federal) |
| US EO 14412 | PQC key establishment for high-value and high-impact systems | 2030-12-31 | Mandatory (federal) |
| EU | High-risk use cases migrated | 2030-12-31 | Guidance |
| US NIST | Quantum-vulnerable public-key algorithms deprecated | After 2030 | Federal guidance |
| US EO 14412 | PQC signatures for high-value and high-impact systems | 2031-12-31 | Mandatory (federal) |
| UK NCSC | Highest-priority migrations executed | 2031 | Guidance |
| US, EU, UK | Full migration / NIST disallows quantum-vulnerable public-key algorithms | 2035 | Target and guidance |

## What You Can Do Now

Once you have read the schedule, the work turns out to start with an inventory rather than with technology. That is also why the UK spent its 2028 deadline on "discovery."

- **Start with a cryptographic asset inventory.** Collect TLS endpoints, certificates and their chains, code-signing keys, and which version of which library is linked where. A CBOM, which records cryptography as a bill of materials the way an SBOM (software bill of materials) records software, is the format for this inventory.
- **Rank by data lifetime.** The paths carrying data that must remain secret beyond 2030 go first. This is the same reason the US schedule put key exchange first.
- **Finish TLS 1.3 first.** Hybrid key exchange runs on top of TLS 1.3. That is also why the US federal deadline for it (2030-01-02) is set separately.
- **Decide your library path.** Work out in advance whether you can move to an LTS line that enables hybrid by default, and which systems cannot. IR 8547 says to identify systems that cannot support PQC and prioritize them for replacement or retirement.
- **Make crypto agility a design requirement.** Algorithms and groups should be changeable through configuration, not code. Prepare for larger keys and signatures as well. Korea's pilot transition projects named "crypto agility" as their core for the same reason.
- **Ask your supply chain for dates.** Ask when the products and modules you use will support hybrid. In Korea, also check when the KCMVP validation schedule will be reflected in procurement requirements.

## Closing

Place the scattered notices on one line and it becomes clear that 2035 is the end, not the start. Before it, key exchange moves ahead of signatures, and the default that bridges the two is hybrid. The US attached enforcement to its dates, and Europe and the UK fixed their waypoints. Korea set dates for its validation program and a legal basis at the same time.

But "it has become the default" and "it interoperates cleanly" are different statements. Browsers and large CDNs turning on hybrid does not mean the clients and servers of an in-house system run the same library version. How does an older version that does not know the hybrid group handle the larger ClientHello? Does negotiation quietly fall back to the classical scheme, or does it fail? What error does a party that cannot read a hybrid certificate produce? In [the next post](/en/blog/pqc-hybrid-tls-interop/) I cover the results of measuring this directly in an environment with mixed versions.

## Sources

- NIST, [Transition to Post-Quantum Cryptography Standards (NIST IR 8547), 2026-10](https://csrc.nist.gov/pubs/ir/8547/final) — [PDF](https://nvlpubs.nist.gov/nistpubs/ir/2026/NIST.IR.8547.pdf)
- NIST, [NIST Report Provides Guidelines for Transition to Post-Quantum Cryptography Standards](https://www.nist.gov/news-events/news/2026/10/nist-report-provides-guidelines-transition-post-quantum-cryptography)
- NIST, [FIPS 203 (ML-KEM)](https://csrc.nist.gov/pubs/fips/203/final)
- NIST, [NIST Selects HQC as Fifth Algorithm for Post-Quantum Encryption, 2025-03-11](https://www.nist.gov/news-events/news/2025/03/nist-selects-hqc-fifth-algorithm-post-quantum-encryption)
- Cloudflare, [The White House's post-quantum executive order is an important milestone, 2026-06-23](https://blog.cloudflare.com/post-quantum-eo-2026)
- NIS Cooperation Group, [A Coordinated Implementation Roadmap for the Transition to Post-Quantum Cryptography, 2025-06](https://digital-strategy.ec.europa.eu/en/library/coordinated-implementation-roadmap-transition-post-quantum-cryptography)
- UK NCSC, [Timelines for migration to post-quantum cryptography, 2025-03-20](https://www.ncsc.gov.uk/guidance/pqc-migration-timelines)
- National Cyber Security Center (Korea), [Notice on PQC Validation Target Candidates and Schedule (in Korean), 2026-09-01](https://www.ncsc.go.kr/ko/main/PageLink.html?token=MDEyMzQ1Njc4OWFiY2RlZrBvBnCd4cC_Aqu-HrYk1bjY5ceD7POZ8O6txZr6KvMeZJhRV8iq7IvhLELla-3OsbsNHB7kv4F1xQZdO5h8TljYDwsJs4Rw-xrvJJfRBtvp) (attachment 「양자내성암호_검증대상_후보군_및_추진_일정_공지.pdf」)
- KISA Cryptography Usage Promotion, [Next-Generation Cryptography — Post-Quantum Cryptography (in Korean)](https://seed.kisa.or.kr/kisa/ngc/pqc.do)
- Korea Law Information Center, [Act on the Promotion of Quantum Science, Technology and Industry (Act No. 21649, effective 2026-11-20) (in Korean)](https://www.law.go.kr/LSW/lsInfoP.do?lsiSeq=286075)
- Financial News (via News1), [Report on the NIS and Ministry of Science and ICT comprehensive PQC transition plan (in Korean), 2023-07-12](https://www.fnnews.com/news/202307121011439692)
- Byline Network, [Government expands PQC transition to five sectors; the key is "crypto agility" (in Korean), 2026-01](https://byline.network/2026/01/28-578/)
- Google Security Blog, [A new path for Kyber on the web, 2024-09-13](https://security.googleblog.com/2024/09/a-new-path-for-kyber-on-web.html)
- OpenSSL, [NEWS.md (3.5 branch)](https://github.com/openssl/openssl/blob/openssl-3.5/NEWS.md)
- Cloudflare, [The 2025 Cloudflare Radar Year in Review](https://blog.cloudflare.com/radar-2025-year-in-review/)
- IETF, [RFC 10024 — Post-Quantum Traditional (PQ/T) Hybrid Key Agreement Mechanisms for TLS 1.3](https://www.rfc-editor.org/rfc/rfc10024.html)
