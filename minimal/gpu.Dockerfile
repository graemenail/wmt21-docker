

FROM nvidia/cuda:11.7.1-devel-ubuntu22.04 AS builder
ENV NVIDIA_DRIVER_CAPABILITIES=compute
ENV DEBIAN_FRONTEND=noninteractive

# Intel MKL
ADD https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB /tmp
RUN apt-key add /tmp/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB \
    && echo deb https://apt.repos.intel.com/mkl all main > /etc/apt/sources.list.d/intel-mkl.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends intel-mkl-64bit-2020.0-088;

RUN apt-get update \
    && apt-get install -y \
        autoconf \
        automake \
        cmake \
        git \
        libev++-dev \
        libssl-dev \
        libtool \
        libboost-chrono-dev \
        libboost-filesystem-dev \
        libboost-iostreams-dev \
        libboost-program-options-dev \
        libboost-regex-dev \
        libboost-system-dev \
        libboost-thread-dev \
        libboost-timer-dev \
        libgoogle-perftools-dev \
        libpcre3-dev \
        libprotobuf-dev \
        protobuf-compiler \
        python3-pip \
        unzip \
        wget

# The ignore-me file is so that the COPY --from in the deploy step never fails
RUN mkdir -p /opt/marian && touch /opt/marian/ignore-me

# Build marian for CPU
FROM builder as buildermarian
ARG MARIAN_CPU_ARCH="icelake-server"
COPY marian-dev marian-gpu
RUN --mount=type=cache,target=/marian-gpu/build \
    cd marian-cpu \
    && mkdir -p build \
    && cd build \
    && CFLAGS="-march=${MARIAN_CPU_ARCH} -pipe" \
       CXXFLAGS="-march=${MARIAN_CPU_ARCH} -pipe" \
       cmake .. \
        -DCMAKE_INSTALL_PREFIX:PATH=/opt/marian \
        -DBUILD_ARCH=${MARIAN_CPU_ARCH} \
        -DCMAKE_BUILD_TYPE=Release \
        -DUSE_STATIC_LIBS=ON \
        -DCOMPILE_CPU=NO \
        -DCOMPILE_CUDA=YES \
        -DCOMPILE_SERVER=OFF \
        -DCOMPILE_TESTS=OFF \
        -DCOMPILE_EXAMPLES=OFF \
        -DUSE_SENTENCEPIECE=ON \
        -DUSE_FBGEMM=OFF \
        -DUSE_DOXYGEN=OFF \
        -DUSE_MKL=ON \
        -DUSE_MPI=OFF \
    && make -j2 marian_decoder marian_conv \
    && objcopy --only-keep-debug marian-decoder marian-decoder.dbg \
    && strip -s marian-decoder \
    && objcopy --add-gnu-debuglink=marian-decoder.dbg marian-decoder \
    && cp marian-decoder marian-decoder.dbg marian-conv /opt/marian/


FROM builder AS builderparallel
ARG MARIAN_CPU_ARCH="icelake-server"
COPY preprocess/ /preprocess
RUN --mount=type=cache,target=/preprocess/build rm -rf /preprocess/build/* \
    && cd /preprocess/build \
    && CFLAGS="-pipe -static -Os -lrt -Wl,--whole-archive -lpthread -Wl,--no-whole-archive" \
       CXXFLAGS="-pipe -static -Os -lrt -Wl,--whole-archive -lpthread -Wl,--no-whole-archive" \
       cmake .. \
        -DBoost_USE_STATIC_LIBS=On\
        -DCMAKE_BUILD_TYPE=Release \
    && make -j qparallel \
    && strip -s bin/qparallel \
    && cp bin/qparallel /opt/marian/qparallel

# Convert shortlist
FROM builder AS shortlist
ARG MODEL='model'
COPY --from=buildercpu /opt/marian/marian-conv /
COPY ${MODEL} /model
RUN cd model && /marian-conv \
    --shortlist lex.s2t.gz 100 100 0 \
    --dump lex.s2t.bin \
    --vocabs vocab.spm vocab.spm

# Convert model
FROM builder AS alphas
ARG MODEL='model'
ARG SRC='en'
ARG TRG='de'

# Get sacrebleu and create a tuning set
RUN pip3 install sacrebleu
RUN --mount=type=cache,target=/root/.sacrebleu \
    for wmt in wmt16 wmt17 wmt18 wmt19 wmt20 wmt21; do \
        sacrebleu -t $wmt -l $SRC-$TRG --echo src; \
    done > /alphatune.input

COPY --from=buildercpu /opt/marian/marian-* /
COPY marian-dev/scripts/alphas/extract_stats.py /
COPY ${MODEL} /model

RUN cd model \
    && /marian-decoder \
        -m model.npz.best-bleu-detok.npz \
        -v vocab.spm vocab.spm \
        --shortlist lex.s2t.gz 100 100 0 \
        -i /alphatune.input \
        -o /dev/null \
        --beam-size 1 --mini-batch 32 --maxi-batch 100 --maxi-batch-sort src -w 512 \
        --skip-cost  --cpu-threads 1 \
        --quiet --quiet-translation \
        --gemm-type intgemm8 --intgemm-options dump-quantmult \
        2> quantmults \
    && /extract_stats.py quantmults model.npz.best-bleu-detok.npz model.alphas.npz \
    && /marian-conv -f model.alphas.npz -t model.intgemm.alphas.bin --gemm-type intgemm8

# Combine and compress model
FROM builder AS model
COPY --from=shortlist /model/vocab.spm /model/lex.s2t.bin /model/
COPY --from=alphas /model/model.intgemm.alphas.bin /model/
RUN cd model \
    && xz -zec model.intgemm.alphas.bin > model.intgemm.alphas.bin.xz \
    && xz -zec vocab.spm > vocab.spm.xz \
    && xz -zec lex.s2t.bin > lex.s2t.bin.xz

# FROM builder AS builderxz
# RUN wget "https://tukaani.org/xz/xz-5.2.6.tar.gz" \
#     && tar -xzf xz-5.2.6.tar.gz

# RUN --mount=type=cache,target=build \
#     cd build \
#     && ../xz-5.2.6/configure \
#         --prefix=/opt \
#         --enable-encoders= \
#         --enable-decoders=lzma1 \
#         --enable-small \
#         --enable-static \
#         --disable-shared \
#         --disable-debug \
#         --disable-silent-rules \
#         --disable-nls \
#         CFLAGS="-Os -m64 -s -static -fPIC" \
#         CPPFLAGS="-Os -m64 -s -static -Wl,--no-as-needed -flinker-output=exec" \
#         LDFLAGS="-static-libgcc -static-libstdc++" || (cat config.log; exit 127) \
#     && make src/xz/xz \
#     && ldd src/xz/xz


# FROM golang:1.15 as buildergoxz
# RUN CGO_ENABLED=0 GOOS=linux go get -a -ldflags '-s -w' github.com/jelmervdl/xz/cmd/xz


# Deploy
# FROM base

# COPY --from=buildercpu /opt/marian/* /
# COPY --from=builderparallel /opt/marian/* /
# RUN rm -f /ignore-me

# COPY --from=model /model.tar.xz /model/model.tar.xz

# # Runner
# COPY marian-parallel.sh init.sh run.sh /
# RUN chmod +x /*.sh

# # Entrypoint extracts model and runs CMD as command through /bin/sh
# ENTRYPOINT ["/init.sh"]

# # CMD ["CPU-1", "latency"]
# CMD ["/run.sh", "CPU-1", "latency"]

FROM alpine:3.14
RUN apk add --no-cache xz numactl-tools bash
ARG MODEL='model'
# COPY --from=model /model/*.xz /model/
COPY model/*.xz /model/
COPY marian-parallel.sh /usr/local/bin
COPY run.sh /
COPY --from=builderparallel /opt/marian/qparallel /usr/local/bin/
COPY --from=buildermarian /opt/marian/marian-decoder /usr/local/bin/
RUN chmod +x /usr/local/bin/*
RUN chmod +x /run.sh
ENTRYPOINT ["/run.sh"]
