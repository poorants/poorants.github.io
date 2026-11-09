+++
title = "Switch Key Exchange Now, Certificates Slowly: Hybrid PQC TLS Measured"
date = 2026-11-12T00:00:00+09:00
draft = false
tags = ["security", "cryptography", "post-quantum", "tls", "openssl"]
description = "I mixed OpenSSL 3.0, 3.2, 3.5 and Go over hybrid post-quantum TLS. Key exchange is cheap enough to switch now; certificates are the expensive part."
+++

"Post-quantum key exchange is now the default" is true. OpenSSL 3.5 and Go 1.25 connect with hybrid key exchange (X25519MLKEM768) with no configuration. But connect an OpenSSL 3.0 client to a 3.5 server and the connection settles on X25519. No error, no warning. You can upgrade the server and call the migration done, and everything still looks fine. That looking-fine is the danger.

[The post-quantum transition timeline](/en/blog/pqc-transition-timeline-2035/) put key exchange ahead of signatures. This time I measured what actually connects and what breaks when versions are mixed, and how much bigger and slower things get. The result fits in one sentence: switch key exchange now, and don't rush certificates; serve both.

## I mixed the versions and connected every pair

I designed the experiment, and an agent (Claude Code) built and ran it. Only public open-source software was used. OpenSSL 3.0, 3.2 and 3.5 as shipped by Linux distributions, plus Go 1.25, each ran in its own container, and every server was connected to every client. Ubuntu 22.04 ships 3.0, Fedora 40 ships 3.2 and Debian 13 ships 3.5 as the default package, which makes this a plausible picture of what servers in production run today. For each connection I recorded the negotiated method, the bytes exchanged and the time taken.

| Client → Server | Old server (3.0, 3.2) | 3.5 server (defaults) | 3.5 server (PQC certificate) |
|---|---|---|---|
| Old (3.0, 3.2) | Classical | Classical (no warning) | Fails |
| OpenSSL 3.5 | Classical | **Hybrid** | **Hybrid + PQC certificate** |
| Go 1.25 | Classical | **Hybrid** | Fails |

"Classical" means X25519 key exchange; "PQC certificate" means a certificate signed with ML-DSA-65. Hybrid appears only where both sides are new.

## Upgrade one side and everything looks fine

A 3.5 server prefers hybrid first, but if the peer doesn't know it, the server settles on X25519. The connection succeeds and nothing in the logs warns you. The only sign is the name of the negotiated group. If you don't record it, you can't count how many connections to older versions remain.

Counting server versions gives the wrong answer. Even if every server runs 3.5, every connection from a 3.0 client is classical. What you need to count is not server versions but the group negotiated on each connection. The other way round, when a 3.5 client sends only the hybrid public key and meets an old server, the server asks it to send something else (HelloRetryRequest). The connection works, but the extra round trip made it 24% slower.

Nor can you force hybrid from the old side. 3.0 and 3.2 don't recognize the hybrid group names and reject them at configuration time. With an extension module (oqs-provider) loaded, an old version's hybrid key exchange did connect to 3.5, but it wasn't on by default and had to be configured by hand. The migration happens only when both sides, client as well as server, are new.

Is there anything that stops this quiet fallback? An attacker in the middle who strips the hybrid entry to force the old method is already stopped: TLS 1.3 covers the whole handshake, including the client's original list, with the server's signature, so tampering breaks the connection ([RFC 8446](https://www.rfc-editor.org/rfc/rfc8446#section-4.4.3)). What it does not stop is a peer that really is old and legitimately agrees on the classical group. That part belongs to operations, not the protocol: log the negotiated group on every connection (in nginx, the [`$ssl_curve`](https://nginx.org/en/docs/http/ngx_http_ssl_module.html#var_ssl_curve) variable), then tighten to hybrid-only starting with the links where you control both ends.

## Key exchange is cheap enough to switch now

Between two 3.5 instances I ran 500 connections, three times over, and compared the median time. Classical took 1.00ms; hybrid key exchange took 1.24ms, 23% more. Server CPU went from just 0.42ms to 0.52ms per connection. In Go the increase was similar in kind, from 0.85ms to 1.13ms. ML-KEM-768 encapsulation ran at about 27,000 operations per second on this machine, so a single computation per connection is barely a cost.

The size is manageable too. The first message a client sends to open a connection (the ClientHello) grew from 236 bytes on the old versions to 1,471 bytes with 3.5 defaults, about six times larger, because it carries a hybrid public key of over 1 KB. As a result it went out as two TCP segments (1,448 + 28 bytes). Configured to send only the hybrid public key, it is 1,413 bytes and fits in one segment. Servers and clients reassemble them without trouble; if you have middleboxes that look only at the first packet, they are worth checking once.

## Certificates are the expensive part

Switching the certificate to PQC as well is a different story. The certificate chain the server sends grew from 926 bytes to 11,180 bytes, twelve times larger. Connection time rose to 1.96ms, 96% above classical, and server CPU rose to 1.82ms per connection, more than four times as much. In this build one ML-DSA-65 signature was about 46 times slower than an ECDSA signature. The implementation matters a lot: a server using another open-source implementation (liboqs) used 2.5 times less server CPU.

The reason for the growth is simple. A PQC certificate carries a 1,974-byte public key and an even larger signature, and the chain carries two such certificates. The signature the server produces on every connection also grows from 79 bytes to 3,317 bytes. Key exchange makes one public key per connection bigger; certificates make the whole chain bigger.

The bigger problem is compatibility. The old versions and Go could not connect to a server that held only a PQC certificate. All they got was alert 40, "handshake failure", a short rejection that doesn't say what didn't match.

The bridge is dual certificates. Put both an ECDSA certificate and an ML-DSA certificate on the server, and it picks the one the client understands. In this experiment the old versions and Go got ECDSA, 3.5 got ML-DSA, and all of them connected. But 3.5 clients took the ML-DSA chain with default settings, so as new clients grow in number, the bytes and CPU the server spends grow with them. One more reason to move certificates slowly.

## Closing

"It's the default now" describes newly made connections. What operators face is the clients and servers already deployed, and there are always old versions mixed in. What these numbers show is that the mix doesn't surface as failures; it hides behind successes.

The order is the same as in the previous post's timeline. Key exchange costs about a quarter more, so it can be switched now. But upgrading the server alone changes nothing, so upgrade clients and servers together, and record the negotiated group to count how many connections to older versions remain. Certificates add a lot of size and CPU and cut off older versions, so there is no reason to rush them. During the transition, serve the old certificate and the PQC certificate side by side, and move over gradually as new clients take over. Looking at these numbers, it makes sense that the deadline for signatures was set a year later than the one for key exchange.

Switch key exchange now, and don't rush certificates; serve both.

The numbers were measured between containers inside a single shared 4 vCPU VM (Xeon Silver 4314, AVX2), so read the timings only as relative comparisons. IETF Composite ML-DSA, still being standardized, has no implementation in the open-source software used here, so it was not measured. Per-version error messages, the full matrix, measurement conditions and reproduction steps are in the [reproduction kit](/blog/pqc-hybrid-tls-interop/interop/README.txt).
