## build environment
FROM alpine:edge as buildimage

# do the installation
ENV TZ="Europe/Vienna"

RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
RUN apk update
RUN apk add build-base tzdata cmake samurai
RUN apk add curl-dev rhash-dev jsoncpp-dev tinyxml2-dev boost-dev zlib-dev htmlcxx-dev@testing
RUN apk add wget curl jq tar gzip

# build the application
WORKDIR /build
RUN wget $(curl -s "https://api.github.com/repos/sude-/lgogdownloader/releases/latest" | jq -r '.assets[].browser_download_url') -O /tmp/archive.tar.gz
RUN cd /build
RUN tar zxf /tmp/archive.tar.gz && rm -f /tmp/archive.tar.gz && cd $(ls) && ls -l

RUN cd $(ls) && ls -l && \
	cmake -B build -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -GNinja && \
	ninja -Cbuild install

# cleanup
RUN apk del build-base cmake samurai wget jq tar gzip

## runtime docker
FROM alpine:edge 
RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
RUN apk --no-cache add ca-certificates
RUN apk --no-cache add curl rhash jsoncpp tinyxml2 zlib htmlcxx@testing boost
WORKDIR /build

COPY --from=buildimage /usr/bin/lgogdownloader /usr/bin/lgogdownloader
COPY runme.sh /
RUN chmod +x /runme.sh
ENTRYPOINT ["/runme.sh"]

