# Hybrid post-quantum TLS interop experiment

Reproduces the measurements in the post: which OpenSSL versions negotiate
`X25519MLKEM768` (codepoint 0x11EC) with which, what happens when an old
version meets an unknown group or an ML-DSA certificate, how big the
ClientHello and certificate chain get, and what a handshake costs.

Only public open-source software is used: distribution OpenSSL packages,
liboqs + oqs-provider (pinned release tags), Go `crypto/tls`, testssl.sh (v3.2.5) and
tlsfuzzer (`TLSFUZZER_REF`, default: current HEAD) with tlslite-ng 0.9.0b2. Everything runs in Docker containers on one host.

## Requirements

- Linux host with Docker (tested with Docker 29)
- `python3` on the host (only for `src/summarize.py`)
- Network access for `docker build` (base images, liboqs/oqs-provider sources)
  and for the optional `scan` / `fuzz` phases (git clones into `ext/`, kept
  apart from `src/`; the cloned tools only run inside containers)

## Run

```sh
./run.sh                 # everything: build certs servers matrix capture latency speed scan fuzz summary stop
./run.sh build certs servers matrix summary    # just the negotiation matrix
N=200 ./run.sh servers latency summary stop    # fewer handshakes per configuration
```

Results land in `results/`:

| file | content |
|---|---|
| `versions.tsv` | exact library versions in each image |
| `cert-sizes.txt`, `cert-crosscheck.txt` | DER sizes of every certificate; cross-implementation verification of ML-DSA chains |
| `matrix.jsonl` / `matrix.csv` / `matrix-tables.txt` | one handshake per client x server x client-group setting: outcome, negotiated group, HelloRetryRequest, message sizes, error text |
| `capture.tsv`, `pcap/` | ClientHello on the wire: number of TCP segments (TSO/GSO off), segment payload sizes |
| `latency.jsonl` / `latency.csv` | N full handshakes x 3 repetitions per configuration: median / p95 wall time, client and server CPU per handshake |
| `speed.txt` | `openssl speed` primitive costs |
| `scan-*.txt` | testssl.sh output against the local servers |
| `fuzz-tls13-mlkem.txt`, `fuzz-categories.txt` | tlsfuzzer `test-tls13-mlkem.py` against the OpenSSL 3.5 server (port 4436) |

## What is in the containers

| image | base | TLS library |
|---|---|---|
| `pqc/ossl30` | ubuntu:22.04 | OpenSSL 3.0.x (distro) |
| `pqc/ossl32` | fedora:40 | OpenSSL 3.2.x (distro) |
| `pqc/ossl35` | debian:trixie | OpenSSL 3.5.x LTS (distro) |
| `pqc/ossl30-oqs` | ubuntu:22.04 | OpenSSL 3.0.x + liboqs 0.16.0 + oqs-provider 0.12.0 |
| `pqc/ossl32-oqs` | fedora:40 | OpenSSL 3.2.x + liboqs 0.16.0 + oqs-provider 0.12.0 |
| `pqc/go` | golang:1.25 | Go `crypto/tls` |

Each OpenSSL image compiles `src/hsprobe.c` against its own libssl. The probe
does full TLS 1.3 handshakes (no tickets, no resumption, chain verified against
the test root) and records sizes from the message callback. `src/goprobe.go`
does the same in Go.

Servers are `openssl s_server -www -num_tickets 0` on a Docker bridge network:

| port | certificate chain (leaf + intermediate) | server groups |
|---|---|---|
| 4431 | ECDSA P-256 | library default |
| 4432 | ECDSA P-256 | `X25519MLKEM768` only |
| 4433 | ML-DSA-65 | library default |
| 4434 | ECDSA P-256 + ML-DSA-65 (`-dcert`, picked by client sigalgs) | library default |
| 4435 | oqs-provider `p384_mldsa65` (OQS hybrid signature, experimental OID) | library default |
| 4436 | ECDSA P-256 (OpenSSL 3.5 only, tlsfuzzer target) | X25519MLKEM768, SecP256r1MLKEM768, SecP384r1MLKEM1024, X25519, P-256 |

On the 3.2+oqs server the ML-DSA ports (4433, 4435) are started with
`-groups X25519MLKEM768:X25519:secp256r1`, because oqs-provider groups are not
in OpenSSL's default server group list. OpenSSL 3.0 + oqs-provider cannot
serve an ML-DSA certificate at all (see `cert-crosscheck.txt`), so it only runs
ports 4431/4432.

Client group settings: `DEFAULT` (library default list and key shares),
`X25519MLKEM768` (hybrid only), `X25519` (classical only),
`X25519MLKEM768:X25519` (hybrid preferred, key share for hybrid only, so a
server without ML-KEM must send HelloRetryRequest).

## Caveats

- Same-host Docker bridge (veth), not a real network: latency numbers show
  relative CPU/size cost, not WAN round trips.
- One machine, one run; repetitions are reported as a range. The host was a
  shared 4-vCPU VM, so background load adds noise (load average is logged in
  `results/host.txt`).
- Distribution OpenSSL builds carry distro patches and policies (Fedora
  crypto-policies, Ubuntu patches); results are for those builds.
- Certificates are throwaway test certificates generated at run time.
