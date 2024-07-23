FROM alpine:3.14

RUN apk update
RUN apk add --no-cache openssh bash
RUN apk --no-cache add openjdk11 --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community


RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY . .

RUN bash setup.sh

CMD sleep infinity

