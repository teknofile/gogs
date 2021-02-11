FROM golang:alpine3.11 AS binarybuilder
RUN apk --no-cache --no-progress add --virtual \
  build-deps \
  build-base \
  git \
  linux-pam-dev

WORKDIR /gogs.io/gogs
COPY . .
RUN make build TAGS="cert pam"

FROM golang:1.14-alpine3.12 AS gosubuilder
RUN apk add --no-cache \
  git \
  file

RUN mkdir -p /go/src/github.com/tianon/gosu

WORKDIR /go/src/github.com/tianon/gosu/

RUN git clone https://github.com/tianon/gosu.git /go/src/github.com/tianon/gosu/
RUN go mod download && go mod verify
RUN go build -v -ldflags='-s -w' -o /gosu


FROM alpine:3.11
#ADD https://github.com/tianon/gosu/releases/download/1.11/gosu-amd64 /usr/sbin/gosu
COPY --from=gosubuilder /gosu /usr/sbin/gosu

RUN chmod +x /usr/sbin/gosu \
  && echo http://dl-2.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories \
  && apk --no-cache --no-progress add \
  bash \
  ca-certificates \
  curl \
  git \
  linux-pam \
  openssh \
  s6 \
  shadow \
  socat \
  tzdata \
  rsync

ENV GOGS_CUSTOM /data/gogs

# Configure LibC Name Service
COPY docker/nsswitch.conf /etc/nsswitch.conf

WORKDIR /app/gogs
COPY docker ./docker
COPY --from=binarybuilder /gogs.io/gogs/gogs .

RUN ./docker/finalize.sh

# Configure Docker Container
VOLUME ["/data", "/backup"]
EXPOSE 22 3000
ENTRYPOINT ["/app/gogs/docker/start.sh"]
CMD ["/bin/s6-svscan", "/app/gogs/docker/s6/"]
