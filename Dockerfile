FROM alpine:latest AS build-env

ENV MECAB_WORK=/tmp/mecab
ENV NEOLOGD_WORK=/tmp/neologd
ENV MECAB_DIC_PATH=/usr/lib/mecab/dic/neologd

# dependencies
RUN set -x && apk add --no-cache git wget bash build-base curl file openssl perl sudo
RUN mkdir -p ${MECAB_DIC_PATH}

# mecab
WORKDIR ${MECAB_WORK}
RUN git clone https://github.com/taku910/mecab.git ${MECAB_WORK} && \
    cd ./mecab && ./configure --enable-utf8-only && make && make install

# neologd
WORKDIR ${NEOLOGD_WORK}
RUN git clone --depth 1 https://github.com/neologd/mecab-ipadic-neologd.git ${NEOLOGD_WORK}

# upstream installer の HTTPS probe で証明書検証を維持し、回避指定が残れば停止する。
RUN set -eu; \
    installer=./bin/install-mecab-ipadic-neologd; \
    if grep -Fq -- 'curl --insecure -IL https://github.com' "${installer}"; then \
        sed -i 's@curl --insecure -IL https://github.com@curl -IL https://github.com@' "${installer}"; \
    fi; \
    grep -Fq -- 'curl -IL https://github.com' "${installer}"; \
    if grep -Fq -- '--insecure' "${installer}"; then \
        echo 'TLS verification bypass remains in the upstream installer' >&2; \
        exit 1; \
    fi

RUN ./bin/install-mecab-ipadic-neologd -n -y -p ${MECAB_DIC_PATH}

FROM alpine:latest
COPY --from=build-env ${MECAB_DIC_PATH} ${MECAB_DIC_PATH}
