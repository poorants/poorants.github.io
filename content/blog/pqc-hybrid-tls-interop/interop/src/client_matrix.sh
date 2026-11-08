#!/bin/sh
# Run one handshake per (endpoint x group mode) from this client image.
#   client_matrix.sh <client-tag> <cafile> <endpoint...>
# Prints JSONL (one hsprobe/goprobe record per line, with client/server/mode added),
# and on failure the last stderr lines of `openssl s_client -brief` as "sclient".
tag=$1; ca=$2; shift 2
for ep in "$@"; do
  host=${ep%:*}; port=${ep#*:}
  if [ "$tag" = go ]; then
    for m in default hybrid x25519; do
      r=$(goprobe "$ep" $m 1 "$ca")
      echo "{\"client\":\"$tag\",\"server\":\"$ep\",\"mode\":\"$m\",${r#\{}"
    done
    continue
  fi
  for m in DEFAULT X25519MLKEM768 X25519 X25519MLKEM768:X25519; do
    r=$(hsprobe "$host" "$port" "$m" DEFAULT 1 "$ca")
    sc=""
    case "$r" in *'"outcome":"fail"'*|*client-config-error*)
      g=""; [ "$m" != DEFAULT ] && g="-groups $m"
      sc=$(echo Q | timeout 5 openssl s_client -brief -connect "$ep" -servername server.test \
             -CAfile "$ca" $g 2>&1 | grep -v -E '^(Q|DONE)$' | tail -3 | tr '\n"\\' '|  ' | cut -c1-400) ;;
    esac
    echo "{\"client\":\"$tag\",\"server\":\"$ep\",\"mode\":\"$m\",\"sclient\":\"$sc\",${r#\{}"
  done
done
