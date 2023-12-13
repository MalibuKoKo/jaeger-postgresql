# syntax = docker/dockerfile:1.4
# https://jwenz723.medium.com/fetching-private-go-modules-during-docker-build-5b76aa690280
# https://stackoverflow.com/questions/61515186/when-using-cgo-enabled-is-must-and-what-happens
FROM golang:1.12.17-alpine3.11 as BUILD

RUN --mount=type=cache,id=apk,target=/var/cache/apk ln -vs /var/cache/apk /etc/apk/cache && \
  apk --update add ca-certificates git

WORKDIR /build

COPY go.mod go.sum ./

RUN --mount=type=cache,id=go,target=/root/.cache/go-build \
 go mod download

COPY . .
RUN --mount=type=cache,id=go,target=/root/.cache/go-build \
  CGO_ENABLED=0 go build \
  -installsuffix 'static' \
  ./cmd/jaeger-pg-store/

FROM alpine:3.19.0 as FINAL
COPY --from=BUILD /build/jaeger-pg-store /go/bin/jaeger-pg-store
RUN mkdir /plugin
# /plugin/ location is defined in jaeger-operator
CMD ["cp", "-r", "/go/bin/jaeger-pg-store", "/plugin/jaeger-pg-store"]

LABEL org.opencontainers.image.source=https://github.com/MalibuKoKo/jaeger-postgresql
LABEL org.opencontainers.image.description="jaeger-postgresql"
LABEL org.opencontainers.image.licenses=MIT