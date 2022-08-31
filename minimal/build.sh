#!/bin/bash
set -euo pipefail

tag=jelmervdl_wmt22_minimal

docker build \
	--build-arg MODEL=student.12-1.tiny \
	--build-arg SRC=en \
	--build-arg TRG=de \
	--progress=plain \
	-t $tag "$@" .

sacrebleu -t wmt19 -l en-de --echo src | docker run -i --rm \
	--cap-add=SYS_PTRACE \
	--security-opt seccomp=unconfined \
	-e SKIP_NUMACTL=1 \
	-e THROUGHPUT_SCRIPT=marian-parallel.sh \
	-e THROUGHPUT_WORKERS=2 \
	-e THROUGHPUT_THREADS=4 \
	-e NUMA_NODE_COUNT=1 \
	$tag CPU-ALL throughput

docker save $tag | pigz -9c > $tag-$(date +'%Y%m%d%H%M%S').tar.gz
