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
