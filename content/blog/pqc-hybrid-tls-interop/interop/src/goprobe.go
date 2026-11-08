// goprobe: Go crypto/tls handshake probe. One JSON line per run.
//   goprobe <host:port> <default|hybrid|x25519> <n> [cafile]
package main

import (
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"fmt"
	"net"
	"os"
	"runtime"
	"sort"
	"strconv"
	"syscall"
	"time"
)

type countConn struct {
	net.Conn
	firstWrite int
}

func (c *countConn) Write(b []byte) (int, error) {
	if c.firstWrite == 0 {
		c.firstWrite = len(b) // first flight = ClientHello record(s)
	}
	return c.Conn.Write(b)
}

func cpu() time.Duration {
	var ru syscall.Rusage
	syscall.Getrusage(syscall.RUSAGE_SELF, &ru)
	return time.Duration(ru.Utime.Nano() + ru.Stime.Nano())
}

func main() {
	addr, mode := os.Args[1], os.Args[2]
	n, _ := strconv.Atoi(os.Args[3])
	cfg := &tls.Config{ServerName: "server.test", MinVersion: tls.VersionTLS13,
		SessionTicketsDisabled: true}
	switch mode {
	case "hybrid":
		cfg.CurvePreferences = []tls.CurveID{tls.X25519MLKEM768}
	case "x25519":
		cfg.CurvePreferences = []tls.CurveID{tls.X25519}
	}
	if len(os.Args) > 4 {
		pem, _ := os.ReadFile(os.Args[4])
		pool := x509.NewCertPool()
		pool.AppendCertsFromPEM(pem)
		cfg.RootCAs = pool
	} else {
		cfg.InsecureSkipVerify = true
	}
	out := map[string]any{"lib": runtime.Version(), "groups": mode}
	var lat []float64
	var errText string
	c0 := cpu()
	for i := 0; i < n; i++ {
		raw, err := net.Dial("tcp", addr)
		if err != nil {
			errText = err.Error()
			break
		}
		cc := &countConn{Conn: raw}
		t := tls.Client(cc, cfg)
		t0 := time.Now()
		err = t.Handshake()
		d := time.Since(t0)
		if err != nil {
			errText = err.Error()
			if i == 0 {
				out["clienthello_record"] = cc.firstWrite
			}
			raw.Close()
			break
		}
		lat = append(lat, float64(d.Microseconds()))
		if i == 0 {
			st := t.ConnectionState()
			out["group"] = st.CurveID.String()
			out["cipher"] = tls.CipherSuiteName(st.CipherSuite)
			out["clienthello_record"] = cc.firstWrite
		}
		t.Close()
	}
	c1 := cpu()
	out["error"] = errText
	out["n"] = len(lat)
	if len(lat) == 0 {
		out["outcome"] = "fail"
	} else {
		out["outcome"] = "ok"
		sort.Float64s(lat)
		out["median_us"] = lat[len(lat)/2]
		out["p95_us"] = lat[int(float64(len(lat))*0.95)]
		out["client_cpu_us"] = float64((c1 - c0).Microseconds()) / float64(len(lat))
	}
	b, _ := json.Marshal(out)
	fmt.Println(string(b))
}
