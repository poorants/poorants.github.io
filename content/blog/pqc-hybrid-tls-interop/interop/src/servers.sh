#!/bin/sh
# Start the s_server endpoints this image can serve; pids go to /run/srv-<port>.
#   servers.sh <certdir> <capabilities: comma list of ecdsa,hybridonly,mldsa,dual,oqshyb,allkems>
C=$1; caps=$2
start() { port=$1; shift
  openssl s_server -accept $port -www -quiet -num_tickets 0 "$@" >/run/srv-$port.log 2>&1 &
  echo $! > /run/srv-$port; }
E="-cert $C/ecdsa/leaf.pem -key $C/ecdsa/leaf.key -cert_chain $C/ecdsa/int.pem"
case ",$caps," in *,ecdsa,*) start 4431 $E ;; esac
case ",$caps," in *,hybridonly,*) start 4432 $E -groups X25519MLKEM768 ;; esac
M=${MLDSA_DIR:-$C/mldsa65}
# PQ_GROUPS: optional -groups for the PQ-signature ports (oqs servers do not offer ML-KEM groups by default)
G=${PQ_GROUPS:+-groups $PQ_GROUPS}
case ",$caps," in *,mldsa,*) start 4433 -cert $M/leaf.pem -key $M/leaf.key -cert_chain $M/int.pem $G ;; esac
case ",$caps," in *,dual,*) start 4434 $E -dcert $M/leaf.pem -dkey $M/leaf.key -dcert_chain $M/int.pem ;; esac
case ",$caps," in *,oqshyb,*) H=$C/p384_mldsa65; start 4435 -cert $H/leaf.pem -key $H/leaf.key -cert_chain $H/int.pem $G ;; esac
case ",$caps," in *,allkems,*) start 4436 $E -groups X25519MLKEM768:SecP256r1MLKEM768:SecP384r1MLKEM1024:X25519:secp256r1 ;; esac
sleep 1; ls /run/srv-* ; exec sleep infinity
