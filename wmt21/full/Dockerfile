FROM nvidia/cuda:11.4.0-base-ubuntu20.04 AS base

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3-minimal xz-utils \
    && apt clean && rm -rf /var/lib/apt/lists/*

# Add?
# ENV NVIDIA_DRIVER_CAPABILITIES=compute

LABEL description="Univeristy of Edinburgh Marian-NMT docker for WMT2021"

ENV DEBIAN_FRONTEND=noninteractive

FROM nvidia/cuda:11.4.0-devel-ubuntu20.04 AS builder
ENV DEBIAN_FRONTEND=noninteractive

# Build Type
ARG CPU_BUILD="ON"
ARG GPU_BUILD="ON"

# Intel MKL
ADD https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB /tmp
RUN if test "${CPU_BUILD}" = "ON"; then \
        apt-key add /tmp/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB \
        && echo deb https://apt.repos.intel.com/mkl all main > /etc/apt/sources.list.d/intel-mkl.list \
        && apt-get update \
        && apt-get install -y --no-install-recommends intel-mkl-64bit-2020.0-088; \
    fi

RUN apt-get update \
    && apt-get install -y \
        autoconf \
        automake \
        binutils \
        cmake \
        g++ \
        git \
        libev++-dev \
        libssl-dev \
        libboost-all-dev \
        libtool \
        libgoogle-perftools-dev \
        libpcre3-dev \
        libprotobuf-dev \
        protobuf-compiler \
        python3-pip \
        unzip \
        wget

RUN mkdir -p /opt/marian

# Build marian for CPU
FROM builder as buildercpu
ARG CPU_BUILD="ON"
ARG MARIAN_CPU_REPO="https://github.com/marian-nmt/marian-dev.git"
ARG MARIAN_CPU_REF="wngt2021maxi"
ARG MARIAN_CPU_ARCH="icelake-server"
RUN if test "${CPU_BUILD}" = "ON"; then \
    git clone ${MARIAN_CPU_REPO} marian-cpu \
    && cd marian-cpu \
    && git checkout ${MARIAN_CPU_REF} \
    && git submodule sync \
    && git submodule update --init --recursive --no-fetch \
    && mkdir build \
    && cd build \
    && CFLAGS="-O3 -march=${MARIAN_CPU_ARCH} -pipe" \
       CXXFLAGS="-O3 -march=${MARIAN_CPU_ARCH} -pipe" \
       cmake .. \
        -DCMAKE_INSTALL_PREFIX:PATH=/opt/marian \
        -DBUILD_ARCH=${MARIAN_CPU_ARCH} \
        -DUSE_STATIC_LIBS=ON \
        -DCOMPILE_CPU=YES \
        -DCOMPILE_CUDA=NO \
        -DCOMPILE_SERVER=OFF \
        -DCOMPILE_TESTS=OFF \
        -DCOMPILE_EXAMPLES=OFF \
        -DUSE_SENTENCEPIECE=ON \
        -DUSE_FBGEMM=OFF \
        -DUSE_DOXYGEN=OFF \
    && make -j marian_decoder \
    && strip marian-decoder \
    && cp marian-decoder /opt/marian/marian-decoder-cpu; \
fi

# Build marian for GPU
FROM builder as buildergpu
ARG GPU_BUILD="ON"
ARG MARIAN_GPU_REPO="https://github.com/XapaJIaMnu/marian-dev.git"
ARG MARIAN_GPU_REF="8bitgpu_maxi"
ARG MARIAN_GPU_ARCH="znver2"
RUN if test "${GPU_BUILD}" = "ON"; then \
    git clone ${MARIAN_GPU_REPO} marian-gpu \
    && cd marian-gpu \
    && git checkout ${MARIAN_GPU_REF} \
    && git submodule sync \
    && git submodule update --init --recursive --no-fetch \
    && mkdir build \
    && cd build \
    && CFLAGS="-O3 -march=${MARIAN_GPU_ARCH} -pipe" \
       CXXFLAGS="-O3 -march=${MARIAN_GPU_ARCH} -pipe" \
       cmake .. \
        -DCMAKE_INSTALL_PREFIX:PATH=/opt/marian \
        -DBUILD_ARCH=${MARIAN_GPU_ARCH} \
        -DUSE_STATIC_LIBS=ON \
        -DCOMPILE_CPU=OFF \
        -DCOMPILE_CUDA=ON \
        -DCOMPILE_CUDA_SM50=OFF \
        -DCOMPILE_CUDA_SM35=OFF \
        -DCOMPILE_CUDA_SM60=OFF \
        -DCOMPILE_CUDA_SM75=OFF \
        -DCOMPILE_SERVER=OFF \
        -DCOMPILE_TESTS=OFF \
        -DCOMPILE_EXAMPLES=OFF \
        -DUSE_SENTENCEPIECE=ON \
        -DUSE_FBGEMM=OFF \
        -DUSE_DOXYGEN=OFF \
    && make -j marian_decoder \
    && strip marian-decoder \
    && cp marian-decoder /opt/marian/marian-decoder-gpu; \
fi

# Compress model
FROM base AS model

ARG MODEL='model'
COPY ${MODEL} /model

RUN cd model && tar -cJf /model.tar.xz .

# Deploy
FROM base
COPY --from=buildercpu /opt/marian/* /
COPY --from=buildergpu /opt/marian/* /
COPY --from=model /model.tar.xz /model/model.tar.xz

# Runner
COPY init.sh run.sh /
RUN chmod +x /*.sh

# Entrypoint extracts model and runs CMD as command through /bin/sh
ENTRYPOINT ["/init.sh"]

# CMD ["CPU-1", "latency"]
CMD ["/run.sh", "CPU-1", "latency"]
