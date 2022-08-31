#!/bin/bash
set -euo pipefail

tag=jelmervdl_wmt22_gpu

docker build \
	-f gpu.Dockerfile \
	--build-arg MARIAN_CPU_ARCH=native \
	--build-arg MODEL=student.12-1.tiny \
	--build-arg SRC=en \
	--build-arg TRG=de \
	--progress=plain \
	-t $tag "$@" .

sacrebleu -t wmt19 -l en-de --echo src | docker run -i --rm $tag CPU-ALL throughput

# docker save $tag | pigz -9c > $tag-$(date +'%Y%m%d%H%M%S').tar.gz
