#!/bin/bash
set -euo pipefail

WORKERS=$1
MARIAN_BINARY="$2"
shift 2

declare -a MARIAN_ARGS=()

while [ "$#" -gt 0 ]; do
	case "$1" in
		--cpu-threads)
			THREADS=$2
			shift 2
			;;
		*)
			MARIAN_ARGS+=($1)
			shift
			;;
	esac
done

export WORKERS
export THREADS_PER_WORKER=$((THREADS / WORKERS))
export MARIAN_BINARY
export MARIAN_ARGS_STR="${MARIAN_ARGS[@]}"

INPUT=$(cat) # Risky memory consumption here
LINECOUNT=$(wc -l <<< $INPUT)
RECSIZE=$(( (LINECOUNT + (WORKERS - 1 )) / WORKERS))

marian-decoder-worker() {
	CORE_FIRST=$(( ( PARALLEL_JOBSLOT - 1) * THREADS_PER_WORKER))
  CORE_LAST=$((PARALLEL_JOBSLOT * THREADS_PER_WORKER))
  MEMBIND=$((PARALLEL_JOBSLOT / ( WORKERS / 2 ) ))
  numactl -C $CORE_FIRST-$CORE_LAST --membind=$MEMBIND \
  $MARIAN_BINARY --cpu-threads $THREADS_PER_WORKER $MARIAN_ARGS_STR
}

parallel --will-cite --pipe --keep-order --line-buffer --jobs $WORKERS -L$RECSIZE marian-decoder-worker
