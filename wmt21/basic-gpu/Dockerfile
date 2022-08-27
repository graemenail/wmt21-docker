FROM nvidia/cuda:11.4.0-base-ubuntu20.04 AS base
# FROM nvidia/cuda:11.4.0-runtime-ubuntu20.04 AS base

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3-minimal \
        xz-utils \
        ;

# User Scripts (init/requirements + aux)
ADD script/ /script
RUN chmod -Rv +x /script && /script/requirements.sh && rm -rf script/requirements.sh

# Attempt cleanup
RUN apt clean && rm -rf /var/lib/apt/lists/*

# Build
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
ADD run.sh /
RUN chmod +x /run.sh

ENTRYPOINT ["/script/init.sh"]
CMD ["/run.sh", "GPU", "throughput"]
