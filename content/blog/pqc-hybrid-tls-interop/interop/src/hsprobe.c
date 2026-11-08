/*
 * hsprobe - TLS 1.3 handshake probe, built against whatever libssl the
 * container ships. One JSON line per run.
 *
 *   hsprobe <host> <port> <groups|DEFAULT> <sigalgs|DEFAULT> <n> [cafile]
 *
 * Records: outcome, negotiated group, HelloRetryRequest, sizes of
 * ClientHello / Certificate / CertificateVerify / ServerHello, bytes on the
 * wire in each direction, per-handshake wall time (median, p95) and client
 * CPU time per handshake.
 */
#include <openssl/ssl.h>
#include <openssl/err.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <netinet/tcp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/socket.h>
#include <time.h>
#include <unistd.h>

struct sizes {
    int ch[2], nch, sh, hrr, cert, cv, ee;
    long wire_out, wire_in;
};
static struct sizes S;

static const unsigned char HRR_RANDOM[32] = {
    0xCF, 0x21, 0xAD, 0x74, 0xE5, 0x9A, 0x61, 0x11, 0xBE, 0x1D, 0x8C, 0x02,
    0x1E, 0x65, 0xB8, 0x91, 0xC2, 0xA2, 0x11, 0x16, 0x7A, 0xBB, 0x8C, 0x5E,
    0x07, 0x9E, 0x09, 0xE2, 0xC8, 0xA8, 0x33, 0x9C};

static void msg_cb(int write_p, int version, int content_type, const void *buf,
                   size_t len, SSL *ssl, void *arg)
{
    const unsigned char *p = buf;
    (void)version; (void)ssl; (void)arg;
    if (content_type == SSL3_RT_HEADER) {
        /* 5-byte record header: count the record length on the wire */
        if (len == 5) {
            long l = 5 + ((p[3] << 8) | p[4]);
            if (write_p) S.wire_out += l; else S.wire_in += l;
        }
        return;
    }
    if (content_type != SSL3_RT_HANDSHAKE || len < 4)
        return;
    switch (p[0]) {
    case 1: /* ClientHello */
        if (write_p && S.nch < 2) S.ch[S.nch++] = (int)len;
        break;
    case 2: /* ServerHello or HRR */
        if (len >= 38 && memcmp(p + 6, HRR_RANDOM, 32) == 0) S.hrr = (int)len;
        else S.sh = (int)len;
        break;
    case 8: S.ee = (int)len; break;
    case 11: if (!write_p) S.cert = (int)len; break;
    case 15: if (!write_p) S.cv = (int)len; break;
    }
}

static int tcp_connect(const char *host, const char *port)
{
    struct addrinfo hints = {0}, *res, *r;
    int fd = -1, one = 1;
    hints.ai_socktype = SOCK_STREAM;
    if (getaddrinfo(host, port, &hints, &res) != 0) return -1;
    for (r = res; r; r = r->ai_next) {
        fd = socket(r->ai_family, r->ai_socktype, r->ai_protocol);
        if (fd < 0) continue;
        if (connect(fd, r->ai_addr, r->ai_addrlen) == 0) break;
        close(fd); fd = -1;
    }
    freeaddrinfo(res);
    if (fd >= 0) setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof one);
    return fd;
}

static double now_us(void)
{
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec * 1e6 + t.tv_nsec / 1e3;
}

static double cpu_us(void)
{
    struct rusage ru;
    getrusage(RUSAGE_SELF, &ru);
    return (ru.ru_utime.tv_sec + ru.ru_stime.tv_sec) * 1e6 +
           ru.ru_utime.tv_usec + ru.ru_stime.tv_usec;
}

static int cmpd(const void *a, const void *b)
{
    double x = *(const double *)a, y = *(const double *)b;
    return x < y ? -1 : x > y;
}

static void json_str(const char *k, const char *v)
{
    printf("\"%s\":\"", k);
    for (; v && *v; v++) {
        if (*v == '"' || *v == '\\') putchar('\\');
        if ((unsigned char)*v >= 0x20) putchar(*v);
    }
    printf("\",");
}

int main(int argc, char **argv)
{
    if (argc < 6) {
        fprintf(stderr, "usage: %s host port groups sigalgs n [cafile]\n", argv[0]);
        return 2;
    }
    const char *host = argv[1], *port = argv[2], *groups = argv[3],
               *sigalgs = argv[4], *cafile = argc > 6 ? argv[6] : NULL;
    int n = atoi(argv[5]), ok = 0, i;
    double *lat = calloc(n, sizeof *lat);
    char err[512] = "", group[64] = "", cipher[64] = "", peer_sig[64] = "";
    struct sizes first = {0};

    SSL_CTX *ctx = SSL_CTX_new(TLS_client_method());
    SSL_CTX_set_min_proto_version(ctx, TLS1_3_VERSION);
    SSL_CTX_set_session_cache_mode(ctx, SSL_SESS_CACHE_OFF);
    SSL_CTX_set_options(ctx, SSL_OP_NO_TICKET);
    if (strcmp(groups, "DEFAULT") && !SSL_CTX_set1_groups_list(ctx, groups)) {
        ERR_error_string_n(ERR_get_error(), err, sizeof err);
        printf("{\"lib\":\"%s\",", OpenSSL_version(OPENSSL_VERSION));
        json_str("groups", groups);
        json_str("sigalgs", sigalgs);
        printf("\"outcome\":\"client-config-error\",");
        json_str("error", err);
        printf("\"n\":0}\n");
        return 1;
    }
    if (strcmp(sigalgs, "DEFAULT") && !SSL_CTX_set1_sigalgs_list(ctx, sigalgs)) {
        ERR_error_string_n(ERR_get_error(), err, sizeof err);
        printf("{\"lib\":\"%s\",", OpenSSL_version(OPENSSL_VERSION));
        json_str("groups", groups);
        json_str("sigalgs", sigalgs);
        printf("\"outcome\":\"client-config-error\",");
        json_str("error", err);
        printf("\"n\":0}\n");
        return 1;
    }
    if (cafile) {
        SSL_CTX_load_verify_locations(ctx, cafile, NULL);
        SSL_CTX_set_verify(ctx, SSL_VERIFY_PEER, NULL);
    }
    SSL_CTX_set_msg_callback(ctx, msg_cb);

    double cpu0 = cpu_us();
    for (i = 0; i < n; i++) {
        memset(&S, 0, sizeof S);
        int fd = tcp_connect(host, port);
        if (fd < 0) { snprintf(err, sizeof err, "connect failed"); break; }
        SSL *ssl = SSL_new(ctx);
        SSL_set_fd(ssl, fd);
        SSL_set_tlsext_host_name(ssl, "server.test");
        double t0 = now_us();
        int r = SSL_connect(ssl);
        double t1 = now_us();
        if (r != 1) {
            unsigned long e = ERR_get_error();
            if (e) ERR_error_string_n(e, err, sizeof err);
            else snprintf(err, sizeof err, "SSL_connect=%d ssl_err=%d", r,
                          SSL_get_error(ssl, r));
            if (i == 0) first = S;
            SSL_free(ssl); close(fd);
            break;
        }
        lat[ok++] = t1 - t0;
        if (i == 0) {
            first = S;
            int nid = SSL_get_negotiated_group(ssl);
            const char *gn = SSL_group_to_name(ssl, nid);
            snprintf(group, sizeof group, "%s", gn ? gn : "?");
            snprintf(cipher, sizeof cipher, "%s", SSL_get_cipher_name(ssl));
            int pnid = 0;
#if OPENSSL_VERSION_NUMBER >= 0x30500000L
            const char *sn = NULL;
            if (SSL_get0_peer_signature_name(ssl, &sn) == 1 && sn)
                snprintf(peer_sig, sizeof peer_sig, "%s", sn);
            else
#endif
            if (SSL_get_peer_signature_type_nid(ssl, &pnid) == 1)
                snprintf(peer_sig, sizeof peer_sig, "%s", OBJ_nid2sn(pnid));
            if (cafile && SSL_get_verify_result(ssl) != X509_V_OK)
                snprintf(err, sizeof err, "verify: %s",
                         X509_verify_cert_error_string(SSL_get_verify_result(ssl)));
        }
        SSL_shutdown(ssl);
        SSL_free(ssl);
        close(fd);
    }
    double cpu1 = cpu_us();

    printf("{\"lib\":\"%s\",", OpenSSL_version(OPENSSL_VERSION));
    json_str("groups", groups);
    json_str("sigalgs", sigalgs);
    printf("\"outcome\":\"%s\",", ok == 0 ? "fail" : (first.hrr ? "ok-hrr" : "ok"));
    json_str("group", group);
    json_str("cipher", cipher);
    json_str("peer_sig", peer_sig);
    json_str("error", err);
    printf("\"clienthello\":%d,\"clienthello2\":%d,\"hrr\":%d,\"serverhello\":%d,"
           "\"certificate\":%d,\"certverify\":%d,\"wire_out\":%ld,\"wire_in\":%ld,",
           first.ch[0], first.ch[1], first.hrr, first.sh, first.cert, first.cv,
           first.wire_out, first.wire_in);
    if (ok > 0) {
        qsort(lat, ok, sizeof *lat, cmpd);
        printf("\"median_us\":%.1f,\"p95_us\":%.1f,\"client_cpu_us\":%.1f,",
               lat[ok / 2], lat[(int)(ok * 0.95) < ok ? (int)(ok * 0.95) : ok - 1],
               (cpu1 - cpu0) / ok);
    }
    printf("\"n\":%d}\n", ok);
    return ok ? 0 : 1;
}
