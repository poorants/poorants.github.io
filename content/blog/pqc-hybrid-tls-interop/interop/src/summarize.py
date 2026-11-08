"""Turn results/*.jsonl into CSV + Markdown tables.  python3 -I summarize.py <resultsdir>"""
import csv, json, os, statistics, sys

R = sys.argv[1]



LEGEND = '''HOW TO READ THIS FILE
=====================
One table per client setting ("client groups"):
  OpenSSL clients (upper-case names):
    DEFAULT                 the client's built-in group list
    X25519MLKEM768          the client offers only the hybrid post-quantum group
    X25519                  the client offers only classical X25519
    X25519MLKEM768:X25519   hybrid key share first, X25519 still allowed
  Go client (lower-case names, row "go"):
    default / hybrid / x25519   the same idea for Go crypto/tls

Rows    = client (ossl30 = OpenSSL 3.0, ossl32 = 3.2, ossl35 = 3.5,
          *-oqs = with oqs-provider, go = Go crypto/tls)
Columns = server: OpenSSL version + certificate
          (ECDSA, ML-DSA-65, ECDSA+ML-DSA dual certificate,
           "hybrid-only" = server accepts only X25519MLKEM768,
           p384_mldsa65 = OQS experimental hybrid signature, not IETF Composite ML-DSA)
Cells   = what the handshake ended with
  X25519MLKEM768   connected with hybrid post-quantum key exchange
  x25519           connected, but classical key exchange only
  FAIL             handshake failed (usually TLS alert 40, handshake_failure)
  n/a (...)        the client version cannot even be configured that way

Example: table "DEFAULT", row ossl30, column "3.5 ECDSA" says x25519 --
an OpenSSL 3.0 client talking to a 3.5 server connects without error but
stays classical. Column "3.5 ECDSA hybrid-only" says FAIL for the same client.

Per-connection sizes, errors and timings are in matrix.csv and latency.csv.
'''

def jl(name):
    p = os.path.join(R, name)
    return [json.loads(l) for l in open(p) if l.strip()] if os.path.exists(p) else []


def short(d):
    o = d["outcome"]
    if o == "ok":
        return d.get("group", "")
    if o == "ok-hrr":
        return "HRR->" + d.get("group", "")
    if o == "client-config-error":
        return "n/a (client cannot configure)"
    return "FAIL"


SERVER_LABEL = {
    "srv30:4431": "3.0 ECDSA",
    "srv32:4431": "3.2 ECDSA",
    "srv32oqs:4431": "3.2+oqs ECDSA",
    "srv32oqs:4432": "3.2+oqs ECDSA hybrid-only",
    "srv32oqs:4433": "3.2+oqs ML-DSA-65",
    "srv32oqs:4435": "3.2+oqs p384_mldsa65",
    "srv35:4431": "3.5 ECDSA",
    "srv35:4432": "3.5 ECDSA hybrid-only",
    "srv35:4433": "3.5 ML-DSA-65",
    "srv35:4434": "3.5 ECDSA+ML-DSA dual",
    "srv30oqs:4431": "3.0+oqs ECDSA",
    "srv30oqs:4432": "3.0+oqs ECDSA hybrid-only",
}

m = jl("matrix.jsonl")
if m:
    keys = ["client", "server", "mode", "outcome", "group", "cipher", "peer_sig",
            "clienthello", "clienthello2", "clienthello_record", "hrr", "serverhello",
            "certificate", "certverify", "wire_out", "wire_in", "error", "sclient", "lib"]
    with open(os.path.join(R, "matrix.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, keys, extrasaction="ignore")
        w.writeheader()
        for d in m:
            w.writerow(d)
    servers = [s for s in SERVER_LABEL if any(d["server"] == s for d in m)]
    clients = list(dict.fromkeys(d["client"] for d in m))
    modes = list(dict.fromkeys(d["mode"] for d in m))
    out = []
    for mode in modes:
        rows = [d for d in m if d["mode"] == mode]
        if not rows:
            continue
        out.append(f"\n### client groups = {mode}\n")
        out.append("| client \\ server | " + " | ".join(SERVER_LABEL[s] for s in servers) + " |")
        out.append("|---" * (len(servers) + 1) + "|")
        for c in clients:
            cells = []
            for s in servers:
                d = next((x for x in rows if x["client"] == c and x["server"] == s), None)
                cells.append(short(d) if d else "")
            if any(cells):
                out.append(f"| {c} | " + " | ".join(cells) + " |")
    open(os.path.join(R, "matrix-tables.txt"), "w").write(LEGEND + "\n".join(out) + "\n")
    print("\n".join(out))

    # sizes: ClientHello per client/mode (first record), Certificate per server
    print("\n### ClientHello handshake-message bytes (first CH; 2nd CH after HRR)")
    seen = set()
    for d in m:
        k = (d["client"], d["mode"])
        ch = d.get("clienthello") or d.get("clienthello_record")
        if k in seen or not ch:
            continue
        seen.add(k)
        print(f"{d['client']:11} {d['mode']:22} CH={ch}")
    print("\n### Certificate / CertificateVerify message bytes per server endpoint")
    seen = set()
    for d in m:
        if d["server"] in seen or not d.get("certificate"):
            continue
        seen.add(d["server"])
        print(f"{SERVER_LABEL.get(d['server'], d['server']):28} Certificate={d['certificate']} "
              f"CertVerify={d.get('certverify')} server->client bytes={d.get('wire_in')}")

lat = jl("latency.jsonl")
if lat:
    groups = {}
    for d in lat:
        groups.setdefault(d["label"], []).append(d)
    rows = []
    for label, ds in groups.items():
        okd = [d for d in ds if d.get("n")]
        if not okd:
            rows.append({"label": label, "outcome": ds[0]["outcome"], "error": ds[0].get("error", "")})
            continue
        rows.append({
            "label": label, "client": ds[0]["client"], "server": ds[0]["server"],
            "outcome": ds[0]["outcome"], "group": ds[0].get("group", ""),
            "n_per_rep": okd[0]["n"], "reps": len(okd),
            "median_us": round(statistics.median(d["median_us"] for d in okd), 1),
            "p95_us": round(statistics.median(d["p95_us"] for d in okd), 1),
            "median_us_range": f"{min(d['median_us'] for d in okd):.0f}-{max(d['median_us'] for d in okd):.0f}",
            "client_cpu_us": round(statistics.median(d["client_cpu_us"] for d in okd), 1),
            "server_cpu_us": round(statistics.median(d["server_cpu_us"] for d in okd), 1),
        })
    keys = ["label", "client", "server", "outcome", "group", "n_per_rep", "reps", "median_us",
            "p95_us", "median_us_range", "client_cpu_us", "server_cpu_us", "error"]
    with open(os.path.join(R, "latency.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, keys, extrasaction="ignore")
        w.writeheader()
        w.writerows(rows)
    print("\n### latency (median of 3 reps; us)")
    for r in rows:
        print("  ".join(f"{k}={r.get(k, '')}" for k in keys if r.get(k, "") != ""))
