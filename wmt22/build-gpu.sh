#!/usr/bin/env bash

set -euo pipefail

BASE="/mnt/surtr0/gnail/wmt22"
MARIAN="$HOME/dev/marian-nmt/build-wmt22-gpu"
MODEL="${BASE}/students/06/student.6-2.base/model/model.npz.best-bleu-detok.npz"

cp ${MARIAN}/marian-decoder .
strip marian-decoder

output="wmt22-gpu"
tag="gnail-gpu"

# --upx \
dockerize -n -o ${output} \
  --debug \
  --symlinks copy-all \
  -a ${MODEL} /model/model.npz \
  -a "${BASE}/vocab/vocab.spm" /model/vocab.spm \
  -a run.sh /run.sh \
  -a /bin/dash /bin/sh \
  -a /usr/lib/x86_64-linux-gnu/libnvidia-ml.so{,} \
  --cmd "/run.sh" \
  $PWD/marian-decoder \
  /usr/bin/xz
# /usr/bin/nvidia-smi

mv "./${output}/$PWD/marian-decoder" "./${output}/marian-decoder"
xz -T0 -vf "./${output}/model/model.npz"

find "${output}" -type d -empty -delete

(
  cd ${output}
  docker build -t ${tag} .
)

docker save ${tag} >docker-${tag}.image
xz -T0 -fvk docker-${tag}.image

du -sch docker-*
