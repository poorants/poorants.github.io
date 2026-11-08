#!/usr/bin/env bash
# Hybrid post-quantum TLS interop experiment (OpenSSL 3.0 / 3.2 / 3.5, oqs-provider, Go).
# Needs: docker, python3 (for the summary). Everything else runs in containers.
#   ./run.sh [phase...]   phases: build certs servers matrix capture latency speed scan fuzz summary stop
#   (no argument = all phases in order)
set -euo pipefail
cd "$(dirname "$0")"
HERE=$PWD; R=$HERE/results; mkdir -p "$R"
NET=pqcnet; CERTVOL=pqc-certs
N=${N:-500}                       # handshakes per latency configuration
IMAGES="ossl30 ossl32 ossl35 ossl30-oqs ossl32-oqs go"
ENDPOINTS="srv30:4431 srv32:4431 srv35:4431 srv35:4432 srv35:4433 srv35:4434 srv30oqs:4431 srv30oqs:4432 srv32oqs:4431 srv32oqs:4432 srv32oqs:4433 srv32oqs:4435"
SRC="-v $HERE/src:/src:ro"
CERTS="-v $CERTVOL:/certs"

ca_for() { case $1 in
  ossl30|ossl32) echo /certs/ecdsa/root.pem ;;
  ossl35|go)     echo /certs/roots-35.pem ;;
  ossl30-oqs|ossl32-oqs) echo /certs/roots-oqs.pem ;; esac; }

phase_build() {
  for t in $IMAGES; do docker build -q -t pqc/$t -f docker/Dockerfile.$t . ; done
  { for t in ossl30 ossl32 ossl35 ossl30-oqs ossl32-oqs; do
      printf '%s\t%s\t' $t "$(docker run --rm pqc/$t sh -c '. /etc/os-release; echo $PRETTY_NAME')"
      docker run --rm pqc/$t openssl version; done
    for t in ossl30-oqs ossl32-oqs; do
      printf '%s\toqsprovider\t%s\n' $t "$(docker run --rm pqc/$t sh -c 'openssl list -providers | grep -A2 oqsprovider | grep version' | xargs)"; done
    printf 'go\t%s\n' "$(docker run --rm pqc/go head -1 /go-version)"
  } | tee "$R/versions.tsv"
}

phase_certs() {
  phase_stop; docker volume rm -f $CERTVOL >/dev/null; docker volume create $CERTVOL >/dev/null
  { docker run --rm $SRC $CERTS pqc/ossl35 sh /src/mkcerts.sh /certs ecdsa -algorithm EC -pkeyopt ec_paramgen_curve:P-256
    docker run --rm $SRC $CERTS pqc/ossl35 sh /src/mkcerts.sh /certs mldsa65 -algorithm ML-DSA-65
    docker run --rm $SRC $CERTS pqc/ossl30-oqs sh /src/mkcerts.sh /certs mldsa65-oqs -algorithm mldsa65
    docker run --rm $SRC $CERTS pqc/ossl30-oqs sh /src/mkcerts.sh /certs p384_mldsa65 -algorithm p384_mldsa65
  } 2>&1 | grep -E 'der=|OK|rror' | tee "$R/cert-sizes.txt"
  docker run --rm $CERTS pqc/ossl35 sh -c '
    cat /certs/ecdsa/root.pem /certs/mldsa65/root.pem /certs/mldsa65-oqs/root.pem > /certs/roots-35.pem
    cat /certs/roots-35.pem /certs/p384_mldsa65/root.pem > /certs/roots-oqs.pem'
  # cross-implementation check: does each side parse/verify the other side's ML-DSA chain?
  { echo "## OpenSSL 3.5 verifying oqs-provider ML-DSA-65 chain"
    docker run --rm $CERTS pqc/ossl35 openssl verify -CAfile /certs/mldsa65-oqs/root.pem -untrusted /certs/mldsa65-oqs/int.pem /certs/mldsa65-oqs/leaf.pem 2>&1 || true
    echo "## oqs-provider (on 3.0) verifying OpenSSL 3.5 ML-DSA-65 chain"
    docker run --rm $CERTS pqc/ossl30-oqs openssl verify -CAfile /certs/mldsa65/root.pem -untrusted /certs/mldsa65/int.pem /certs/mldsa65/leaf.pem 2>&1 || true
    echo "## OpenSSL 3.0 (no provider) parsing an ML-DSA-65 certificate"
    docker run --rm $CERTS pqc/ossl30 openssl x509 -in /certs/mldsa65/leaf.pem -noout -text 2>&1 | grep -E -i 'Public Key Algorithm|Signature Algorithm|rror' | head -4 || true
    echo "## OpenSSL 3.5 parsing oqs p384_mldsa65 hybrid certificate"
    docker run --rm $CERTS pqc/ossl35 openssl x509 -in /certs/p384_mldsa65/leaf.pem -noout -text 2>&1 | grep -E -i 'Public Key Algorithm|Signature Algorithm|rror' | head -4 || true
    echo "## OpenSSL 3.0 + oqs-provider: s_server with an ML-DSA-65 certificate (default and SECLEVEL=0)"
    for x in "" "-cipher DEFAULT:@SECLEVEL=0"; do
      docker run --rm $CERTS pqc/ossl30-oqs sh -c "C=/certs/mldsa65-oqs; timeout 3 openssl s_server -accept 5555 -www -cert \$C/leaf.pem -key \$C/leaf.key $x 2>&1 | grep -v 'temp DH' | head -2" || true; done
    echo "## OpenSSL 3.2 + oqs-provider: s_server with an ML-DSA-65 certificate"
    docker run --rm $CERTS pqc/ossl32-oqs sh -c "C=/certs/mldsa65-oqs; timeout 3 openssl s_server -accept 5555 -www -cert \$C/leaf.pem -key \$C/leaf.key 2>&1 | head -2; echo '(no output above = loaded and listening until timeout)'" || true
  } | tee "$R/cert-crosscheck.txt"
}

phase_servers() {
  phase_stop
  docker network create $NET >/dev/null
  run_srv() { docker run -d --name $1 --network $NET $SRC $CERTS -e MLDSA_DIR=${3:-} -e PQ_GROUPS=${5:-} pqc/$2 sh /src/servers.sh /certs $4 >/dev/null; }
  run_srv srv30    ossl30     "" ecdsa
  run_srv srv32    ossl32     "" ecdsa
  run_srv srv35    ossl35     "" ecdsa,hybridonly,mldsa,dual,allkems
  run_srv srv30oqs ossl30-oqs "" ecdsa,hybridonly
  run_srv srv32oqs ossl32-oqs /certs/mldsa65-oqs ecdsa,hybridonly,mldsa,oqshyb X25519MLKEM768:X25519:secp256r1
  sleep 3; docker ps --filter network=$NET --format '{{.Names}} {{.Status}}'
}

phase_matrix() {
  : > "$R/matrix.jsonl"
  for t in ossl30 ossl32 ossl35 ossl30-oqs ossl32-oqs go; do
    docker run --rm --network $NET $SRC $CERTS pqc/$t sh /src/client_matrix.sh $t "$(ca_for $t)" $ENDPOINTS >> "$R/matrix.jsonl"
  done
  wc -l "$R/matrix.jsonl"
}

# ClientHello on the wire: capture in the client netns with TSO/GSO off so the
# capture shows real MSS-sized segments.
phase_capture() {
  mkdir -p "$R/pcap"; : > "$R/capture.tsv"
  cap() { name=$1 img=$2 ep=$3 groups=$4
    docker run --rm --network $NET --cap-add NET_ADMIN --cap-add NET_RAW $SRC $CERTS -v "$R/pcap:/out" pqc/$img sh -c "
      ethtool -K eth0 tso off gso off gro off >/dev/null 2>&1
      tcpdump -U -s 0 -i eth0 -w /out/$name.pcap tcp port ${ep#*:} 2>/dev/null & sleep 1
      hsprobe ${ep%:*} ${ep#*:} $groups DEFAULT 1 >/dev/null 2>&1 || true; sleep 1; kill %1" || true
    # client->server segments carrying payload before the first server payload = ClientHello segments
    docker run --rm -v "$R/pcap:/out:ro" pqc/ossl35 sh -c "tshark -r /out/$name.pcap -T fields -e tcp.dstport -e tcp.len -e frame.len 2>/dev/null" |
      awk -v n=$name -v p=${ep#*:} '
        $2>0 && $1!=p {exit} $2>0 && $1==p {s++; b=b (b?"+":"") $2; f=(f>$3?f:$3)}
        END {printf "%s\t%d\t%s\t%d\n", n, s, b, f}' >> "$R/capture.tsv"
  }
  cap ch-30-default        ossl30     srv35:4431 DEFAULT
  cap ch-32-default        ossl32     srv35:4431 DEFAULT
  cap ch-35-default        ossl35     srv35:4431 DEFAULT
  cap ch-35-x25519         ossl35     srv35:4431 X25519
  cap ch-35-hybrid         ossl35     srv35:4431 X25519MLKEM768
  cap ch-35-hybrid-hrr     ossl35     srv30:4431 X25519MLKEM768:X25519
  cap ch-oqs-default       ossl30-oqs srv35:4431 DEFAULT
  cap ch-oqs-hybrid        ossl30-oqs srv35:4431 X25519MLKEM768
  cap ch-oqs32-default     ossl32-oqs srv35:4431 DEFAULT
  echo "# container eth0 mtu=$(docker run --rm --network $NET pqc/ossl35 cat /sys/class/net/eth0/mtu)" >> "$R/capture.tsv"
  column -t "$R/capture.tsv"
}

srv_cpu() { # utime+stime clock ticks of the s_server listening on $2 in container $1
  docker exec $1 sh -c "awk '{print \$14+\$15}' /proc/\$(cat /run/srv-$2)/stat"; }

phase_latency() {
  : > "$R/latency.jsonl"
  { grep -m1 "model name" /proc/cpuinfo; echo "cpus=$(nproc) mem=$(free -g | awk '/Mem/{print $2}')G kernel=$(uname -r) docker=$(docker version -f '{{.Server.Version}}')"
    echo "loadavg before latency: $(cut -d' ' -f1-3 /proc/loadavg)"; } > "$R/host.txt"
  hz=$(docker run --rm pqc/ossl35 getconf CLK_TCK)
  lat() { label=$1 img=$2 ep=$3 groups=$4
    for rep in 1 2 3; do
      s=${ep%:*}
      c0=$(srv_cpu $s ${ep#*:})
      if [ $img = go ]; then
        r=$(docker run --rm --network $NET $CERTS pqc/go goprobe $ep $groups $N "$(ca_for go)" || true)
      else
        r=$(docker run --rm --network $NET $CERTS pqc/$img hsprobe ${ep%:*} ${ep#*:} $groups DEFAULT $N "$(ca_for $img)" || true)
      fi
      c1=$(srv_cpu $s ${ep#*:})
      sc=$(awk -v a=$c0 -v b=$c1 -v hz=$hz -v n=$N 'BEGIN{printf "%.1f", (b-a)*1e6/hz/n}')
      echo "{\"label\":\"$label\",\"rep\":$rep,\"client\":\"$img\",\"server\":\"$ep\",\"server_cpu_us\":$sc,${r#\{}" | tee -a "$R/latency.jsonl"
    done
  }
  lat 35-x25519-ecdsa      ossl35     srv35:4431 X25519
  lat 35-hybrid-ecdsa      ossl35     srv35:4431 X25519MLKEM768
  lat 35-default-ecdsa     ossl35     srv35:4431 DEFAULT
  lat 35-x25519-mldsa      ossl35     srv35:4433 X25519
  lat 35-hybrid-mldsa      ossl35     srv35:4433 X25519MLKEM768
  lat 35-hrr-to-30         ossl35     srv30:4431 X25519MLKEM768:X25519
  lat 35-x25519-to-30      ossl35     srv30:4431 X25519
  lat 30-x25519-ecdsa      ossl30     srv30:4431 X25519
  lat oqs-x25519-ecdsa     ossl30-oqs srv30oqs:4431 X25519
  lat oqs-hybrid-ecdsa     ossl30-oqs srv30oqs:4432 X25519MLKEM768
  lat oqs32-x25519-ecdsa   ossl32-oqs srv32oqs:4431 X25519
  lat oqs32-hybrid-ecdsa   ossl32-oqs srv32oqs:4432 X25519MLKEM768
  lat oqs32-hybrid-mldsa   ossl32-oqs srv32oqs:4433 X25519MLKEM768
  lat oqs32-hybrid-p384mldsa ossl32-oqs srv32oqs:4435 X25519MLKEM768
  lat go-default-35        go         srv35:4431 default
  lat go-x25519-35         go         srv35:4431 x25519
  echo "loadavg after latency: $(cut -d' ' -f1-3 /proc/loadavg)" >> "$R/host.txt"
}

phase_speed() {
  sp() { docker run --rm pqc/$1 openssl speed -seconds 3 "${@:2}" 2>/dev/null | grep -E -A1 -i 'sign|keygen|op/s' | grep -v -E '^(--|options|compiler)'; }
  { echo "## OpenSSL 3.5 (Debian 13): ECDSA P-256, X25519, ML-KEM-768, ML-DSA-65"
    sp ossl35 ecdsap256 ecdhx25519 ML-KEM-768 ML-DSA-65
    echo "## OpenSSL 3.0 (Ubuntu 22.04): ECDSA P-256, X25519"
    sp ossl30 ecdsap256 ecdhx25519
  } | tee "$R/speed.txt"
}

phase_scan() {
  mkdir -p "$HERE/ext"
  [ -d "$HERE/ext/testssl.sh" ] || git clone -q --depth 1 -b ${TESTSSL_TAG:-v3.2.5} https://github.com/testssl/testssl.sh "$HERE/ext/testssl.sh"
  for ep in ${SCAN_EPS:-srv35:4431 srv35:4433 srv30:4431 srv32oqs:4432 srv32oqs:4435}; do
    docker run --rm --network $NET -v "$HERE/ext/testssl.sh:/t:ro" pqc/ossl35 sh -c "
      apt-get -qq update >/dev/null && apt-get -qq install -y bsdextrautils dnsutils procps >/dev/null 2>&1
      cd /tmp && bash /t/testssl.sh --openssl /usr/bin/openssl --warnings off --color 0 -f -P -S --quiet $ep" \
      > "$R/scan-${ep/:/-}.txt" 2>&1 || true
  done
  grep -H -E -i 'Elliptic|groups|KEM|Server key|Signature Algorithm|Key Exch|Forward' "$R"/scan-*.txt | cut -c1-220 || true
}

phase_fuzz() {
  mkdir -p "$HERE/ext"
  [ -d "$HERE/ext/tlsfuzzer" ] || git clone -q https://github.com/tlsfuzzer/tlsfuzzer "$HERE/ext/tlsfuzzer"
  git -C "$HERE/ext/tlsfuzzer" checkout -q ${TLSFUZZER_REF:-HEAD}
  docker run --rm --network $NET -v "$HERE/ext/tlsfuzzer:/f:ro" python:3.12-slim sh -c "
      pip -q install --root-user-action=ignore 'tlslite-ng==0.9.0b2' ecdsa kyber-py 2>&1 | tail -1
      cd /tmp && PYTHONPATH=/f python3 /f/scripts/test-tls13-mlkem.py -h srv35 -p 4436 2>&1" \
    > "$R/fuzz-tls13-mlkem.txt" || true
  # pass/fail per category (probe name with the numeric variant stripped)
  sed -n '/^FAILED:/,$p' "$R/fuzz-tls13-mlkem.txt" | grep "^\s*'" | sed -E "s/ [0-9]+'$/ N'/" | sort | uniq -c > "$R/fuzz-failed-categories.txt" || true
  grep -E '^(TOTAL|PASS|FAIL|SKIP|XFAIL|XPASS):' "$R/fuzz-tls13-mlkem.txt"; cat "$R/fuzz-failed-categories.txt"
}

phase_summary() { python3 -I "$HERE/src/summarize.py" "$R"; }
phase_stop() { docker rm -f srv30 srv32 srv35 srv30oqs srv32oqs >/dev/null 2>&1 || true; docker network rm $NET >/dev/null 2>&1 || true; }

phases=${*:-build certs servers matrix capture latency speed scan fuzz summary stop}
for p in $phases; do echo "=== $p"; phase_$p; done
