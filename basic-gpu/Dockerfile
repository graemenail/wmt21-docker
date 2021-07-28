FROM nvidia/cuda:11.4.0-base-ubuntu20.04 AS base
# FROM nvidia/cuda:11.4.0-runtime-ubuntu20.04 AS base

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3-minimal xz-utils \
    && apt clean && rm -rf /var/lib/apt/lists/*

# Model
FROM base as builder
# Marian
COPY marian* /
RUN apt-get update \
    && apt-get install -y --no-install-recommends binutils \
    && apt clean && rm -rf /var/lib/apt/lists/*

RUN strip marian*

# Model
ARG MODEL='model'
COPY ${MODEL} /model
RUN cd model && tar -cJf /model.tar.xz .

# Deploy
FROM base
COPY --from=builder /marian* /
COPY --from=builder /model.tar.xz /model/model.tar.xz

# Runner
ADD init.sh run.sh /
RUN chmod +x /*.sh

ENTRYPOINT ["/init.sh"]
CMD ["/run.sh", "GPU", "throughput"]
