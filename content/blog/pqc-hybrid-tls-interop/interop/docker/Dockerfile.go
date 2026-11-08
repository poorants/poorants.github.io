# Go crypto/tls client (X25519MLKEM768 on by default since Go 1.24; CurveID needs 1.25)
FROM golang:1.25-bookworm AS build
COPY src/goprobe.go /src/goprobe.go
RUN cd /src && go mod init goprobe >/dev/null 2>&1 && CGO_ENABLED=0 go build -o /goprobe goprobe.go
FROM debian:trixie-slim
COPY --from=build /goprobe /usr/local/bin/goprobe
COPY --from=build /usr/local/go/VERSION /go-version
