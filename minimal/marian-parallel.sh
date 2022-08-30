#!/bin/bash

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

export THREADS_PER_WORKER=$((THREADS / WORKERS))
export MARIAN_BINARY
export MARIAN_ARGS

INPUT=$(cat) # Risky memory consumption here
LINECOUNT=$(wc -l <<< $INPUT)
RECSIZE=$(( (LINECOUNT + (WORKERS - 1 )) / WORKERS))

marian-decoder-worker() {
	numactl -C $(( ( PARALLEL_JOBSLOT - 1) * THREADS_PER_WORKER))-$((PARALLEL_JOBSLOT * THREADS_PER_WORKER)) --membind=1 \
	$MARIAN_BINARY --cpu-threads $THREADS_PER_WORKER ${MARIAN_ARGS[@]}
}


# parallel --will-cite --pipe --keep-order --line-buffer --jobs $WORKERS -L$RECSIZE marian-decoder-worker
export -f marian-decoder-worker
qparallel -j $WORKERS /bin/bash -c marian-decoder-worker
