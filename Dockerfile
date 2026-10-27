FROM alpine:latest AS build-env

ENV MECAB_WORK=/tmp/mecab
ENV NEOLOGD_WORK=/tmp/neologd
ENV MECAB_DIC_PATH=/usr/lib/mecab/dic/neologd

# dependencies
# busybox の cut だと installer の SHA-1 照合が末尾の空白で一致しなくなるので coreutils を入れる。
RUN set -x && apk add --no-cache git wget bash build-base coreutils curl file openssl perl sudo 'ca-certificates-bundle>=20261020-r0'
RUN mkdir -p ${MECAB_DIC_PATH}

# mecab
WORKDIR ${MECAB_WORK}
RUN git clone https://github.com/taku910/mecab.git ${MECAB_WORK} && \
    cd ./mecab && ./configure --enable-utf8-only && make && make install

# neologd
WORKDIR ${NEOLOGD_WORK}
RUN git clone --depth 1 https://github.com/neologd/mecab-ipadic-neologd.git ${NEOLOGD_WORK}

# upstream の installer は curl の証明書検証を切っているので、検証ありに戻してから実行する。
RUN set -eu; \
    files="bin/install-mecab-ipadic-neologd libexec/make-mecab-ipadic-neologd.sh"; \
    sed -i -E 's/curl (-k )?--insecure /curl /' ${files}; \
    if grep -rnE -- '--insecure|--no-check-certificate|curl[^|;&]* -[[:alpha:]]*k([[:space:]]|$)' bin libexec; then exit 1; fi

RUN ./bin/install-mecab-ipadic-neologd -n -y -p ${MECAB_DIC_PATH}

FROM alpine:latest
RUN apk add --no-cache 'ca-certificates-bundle>=20261020-r0'
COPY --from=build-env ${MECAB_DIC_PATH} ${MECAB_DIC_PATH}
