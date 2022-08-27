#!/usr/bin/env bash

set -euo pipefail

BASE="/mnt/surtr0/gnail/wmt22"
MARIAN="$HOME/dev/marian-nmt/build-wmt22-cpu"
# MODEL="${BASE}/students/06/student.12-1.large.v3/model/model.npz.best-bleu-detok.npz"
MODEL="${BASE}/students/06/student.6-2.tiny/model/model.npz.best-bleu-detok.npz"

cp ${MARIAN}/marian-decoder .
strip marian-decoder

output="wmt22-cpu"
tag="gnail-cpu"

dockerize -n -o ${output} \
  --debug \
  -a ${MODEL} /model/model.npz \
  -a "${BASE}/vocab/vocab.spm" /model/vocab.spm \
  -a run.sh /run.sh \
  -a /bin/dash /bin/sh \
  -a /bin/ls{,} \
  --cmd "/run.sh" \
  $PWD/marian-decoder \
  /usr/bin/xz

mv "./${output}/$PWD/marian-decoder" "./${output}/marian-decoder"

# Convert to .bin
# ${MARIAN}/marian-conv --from "${output}/model/model.npz" --to "${output}/model/model.bin"

xz -T0 -vf "./${output}/model/model.npz"

find "${output}" -type d -empty -delete

(
  cd ${output}
  docker build -t ${tag} .
)

docker save ${tag} >docker-${tag}.image
xz -T0 -fvk docker-${tag}.image

du -sch docker-*
