#!/bin/bash
set -euo pipefail

tag=jelmervdl_wmt22_minimal

docker build \
	--build-arg GPU_BUILD=OFF \
	--build-arg MARIAN_CPU_ARCH=native \
	--build-arg MARIAN_CPU_REPO=https://github.com/XapaJIaMnu/marian-dev.git \
	--build-arg MARIAN_CPU_REF=wngt2021avx512 \
	--build-arg MODEL=student.12-1.tiny \
	--build-arg SRC=en \
	--build-arg TRG=de \
	--progress=plain \
	-t $tag "$@" .

echo "hello world!" | docker run --rm $tag -- CPU-ALL throughput

docker save $tag | pigz -9c > $tag-$(date +'%Y%m%d%H%M%S').tar.gz
