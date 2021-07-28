#!/usr/bin/env bash
# -*- coding: utf-8 -*-
set -euo pipefail

MARIAN_OPTIONS=(
  $(cat /extracted-model/*.txt)
  -m /extracted-model/model.npz
  -v /extracted-model/vocab.spm{,}
  -n 0.6 
  -b 1
  --maxi-batch-sort src
  --workspace 128
  --max-length-factor 2.5
  --skip-cost
  --quiet-translation

  #--transformer-head-dim 32
  #--gemm-type intgemm8
  #--intgemm-options all-shifted
  #--intgemm-options shifted all-shifted
)

# Hardware
case $1 in
  "CPU-1")
    BINARY='marian-decoder-cpu'
    MARIAN_OPTIONS+=(
      --cpu-threads 1
      --shortlist /extracted-model/lex.s2t.50.bin 50 50
    )
    ;;
  "CPU-ALL")
    BINARY='marian-decoder-cpu'
    MARIAN_OPTIONS+=(
      --cpu-threads 36
      --shortlist /extracted-model/lex.s2t.50.bin 50 50
    )
    ;;
  *)
    BINARY='marian-decoder-gpu'
    MARIAN_OPTIONS+=(
      --devices 0
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
    MARIAN_OPTIONS+=(
      --mini-batch 32
      --maxi-batch 512
    )
    ;;
  *)
    echo "Not running..." >&2
    exit 1
    ;;
esac

# The tail part is to print only the wall time from the log output
/$BINARY ${MARIAN_OPTIONS[@]} 2> >(tail -n1 >&2)

