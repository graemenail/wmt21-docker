FROM ubuntu:20.04 as base

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    numactl \
    parallel \
    python3-minimal \
    xz-utils \
  && apt clean && rm -rf /var/lib/apt/lists/*

# Prepare
FROM base as builder
# Marian
COPY marian* /
RUN apt-get update \
  && apt-get install -y --no-install-recommends binutils \
  && apt clean && rm -rf /var/lib/apt/lists/*

RUN strip marian*

# Model
ARG MODEL="model"
ARG COMPRESS_MODEL="ON"
COPY ${MODEL} /model

# compress and tidy up (see /init.sh for decompression)
RUN if test "$COMPRESS_MODEL" = "ON"; then \
  cd model && tar --remove-files -cJf model.tar.xz *; \
  fi

# Deploy
FROM base
COPY --from=builder /marian* /
COPY --from=builder /model /model

# With compression off make model files available at same location
RUN if test ! -f /model/model.tar.xz; then \
  ln -s /model /extracted-model; \
  fi

# Runner
ADD init.sh run.sh /
RUN chmod +x /*.sh

ENTRYPOINT ["/init.sh"]
CMD ["/run.sh", "GPU", "throughput"]
