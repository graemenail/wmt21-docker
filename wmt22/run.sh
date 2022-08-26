#!/bin/sh

# set -x

export OMP_NUM_THREADS=1

HARDWARE="$1"  # CPU-1, CPU-ALL, GPU
TASK="$2"  # latency, throughput

MODEL="/model/model.npz"
# ls -valpsh /lib/x86_64-linux-gnu
[ -f "/model/model.npz.xz" ] && xz -T0 --decompress /model/model.npz.xz  # example decompression
if [ -f "/model/model.bin" ]; then
  MODEL="/model/model.bin"
fi

# nvidia-smi
/marian-decoder \
  -m "${MODEL}" \
  -v /model/vocab.spm /model/vocab.spm \
  "${@}"
