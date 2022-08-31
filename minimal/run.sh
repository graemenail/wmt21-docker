#!/bin/bash
# -*- coding: utf-8 -*-
set -euo pipefail

if test ! -d /extracted-model; then
  mkdir /extracted-model
  touch /extracted-model/placeholder.txt
  for f in /model/*.xz; do
    xz -cd $f > /extracted-model/$(basename $f .xz)
  done
fi

MARIAN_OPTIONS=(
  $(cat /extracted-model/*.txt)
  -m /extracted-model/model.intgemm.alphas.bin
  -v /extracted-model/vocab.spm{,}
  -n 0.6
  -b 1
  --maxi-batch-sort src
  --skip-cost
  --quiet-translation
)

# Hardware
case $1 in
  "CPU-1")
    BINARY="marian-decoder"
    MARIAN_OPTIONS+=(
      --cpu-threads 1
      --shortlist /extracted-model/lex.s2t.bin false
      --workspace 512
      --max-length-factor 2.5
      --gemm-type intgemm8
      --intgemm-options precomputed-alpha all-shifted
    )
    ;;
  "CPU-ALL")
    BINARY="marian-parallel.sh 4 marian-decoder"
    MARIAN_OPTIONS+=(
      --cpu-threads 36 # spread across 4 workers, so 9 in practice
      --shortlist /extracted-model/lex.s2t.bin false
      --workspace 512
      --max-length-factor 2.5
      --gemm-type intgemm8
      --intgemm-options precomputed-alpha all-shifted
    )
    ;;
  "GPU")
    BINARY="marian-decoder"
    MARIAN_OPTIONS+=(
      --devices 0
      --maxi-batch-sort src
      --workspace 36000
      --max-length-factor 1.6
      --fp16
    )
    ;;
esac

# Task
case $2 in
  "latency")
    MARIAN_OPTIONS+=( 
      --mini-batch 1
      --maxi-batch 1
    )
    ;;
  "throughput")
    if test "${1:0:3}" = "CPU"; then
      MARIAN_OPTIONS+=(
        --mini-batch 32
        --maxi-batch 512
      )
    else
      MARIAN_OPTIONS+=(
        --mini-batch 768
        --maxi-batch 2048
      )
    fi
    ;;
  *)
    echo "Unknown task..." >&2
    exit 1
    ;;
esac

# The tail part is to print only the wall time from the log output
$BINARY ${MARIAN_OPTIONS[@]} #2> >(tail -n1 >&2)
