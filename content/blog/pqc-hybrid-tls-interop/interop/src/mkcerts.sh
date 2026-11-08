#!/bin/sh
# Build root -> intermediate -> leaf chains for one signature algorithm.
#   mkcerts.sh <outdir> <name> <openssl genpkey args...>
# e.g. mkcerts.sh /certs ecdsa -algorithm EC -pkeyopt ec_paramgen_curve:P-256
#      mkcerts.sh /certs mldsa65 -algorithm ML-DSA-65
set -e
out=$1; name=$2; shift 2
d=$out/$name; mkdir -p "$d"; cd "$d"
for k in root int leaf; do openssl genpkey "$@" -out $k.key; done
cat > ext.cnf <<'X'
[ca]
basicConstraints=critical,CA:TRUE
keyUsage=critical,keyCertSign,cRLSign
subjectKeyIdentifier=hash
[int]
basicConstraints=critical,CA:TRUE,pathlen:0
keyUsage=critical,keyCertSign,cRLSign
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid
[leaf]
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature
extendedKeyUsage=serverAuth
subjectAltName=DNS:server.test
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid
X
openssl req -new -x509 -key root.key -subj "/CN=PQC interop root $name" -days 30 \
  -extensions ca -config ext.cnf -out root.pem
openssl req -new -key int.key -subj "/CN=PQC interop intermediate $name" -config ext.cnf -out int.csr
openssl x509 -req -in int.csr -CA root.pem -CAkey root.key -CAcreateserial -days 30 \
  -extfile ext.cnf -extensions int -out int.pem
openssl req -new -key leaf.key -subj "/CN=server.test" -config ext.cnf -out leaf.csr
openssl x509 -req -in leaf.csr -CA int.pem -CAkey int.key -CAcreateserial -days 30 \
  -extfile ext.cnf -extensions leaf -out leaf.pem
openssl verify -CAfile root.pem -untrusted int.pem leaf.pem
for f in root int leaf; do printf '%s %s.der=%s\n' "$name" $f \
  "$(openssl x509 -in $f.pem -outform DER | wc -c)"; done
printf '%s leaf_pubkey_der=%s\n' "$name" "$(openssl pkey -in leaf.key -pubout -outform DER | wc -c)"
