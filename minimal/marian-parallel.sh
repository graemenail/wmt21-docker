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

export NODE_COUNT=${NUMA_NODE_COUNT-2}
export WORKERS
export THREADS_PER_WORKER=$((THREADS / WORKERS))
export MARIAN_BINARY
export MARIAN_ARGS_STR="${MARIAN_ARGS[@]}"

marian-decoder-worker() {
	set -eu
	CORE_FIRST=$(( ( PARALLEL_JOBSLOT - 1) * THREADS_PER_WORKER))
	CORE_LAST=$((PARALLEL_JOBSLOT * THREADS_PER_WORKER))
	MEMBIND=$((PARALLEL_JOBSLOT / ( WORKERS / NODE_COUNT ) ))
	if [ -z "$SKIP_NUMACTL" ]; then
		numactl -C $CORE_FIRST-$CORE_LAST --membind=$MEMBIND \
		$MARIAN_BINARY --cpu-threads $THREADS_PER_WORKER $MARIAN_ARGS_STR
	else
		$MARIAN_BINARY --cpu-threads $THREADS_PER_WORKER $MARIAN_ARGS_STR
	fi
}

export -f marian-decoder-worker
qparallel -j $WORKERS /bin/bash -c marian-decoder-worker
