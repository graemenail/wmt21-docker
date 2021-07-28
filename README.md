# wmt21-docker

## Variants
### basic-gpu
Builds a docker for GPU usage. Requires a pre-build marian-decoder for the correct architecture.

### basic-cpu
Builds a docker for CPU usage. Requires a pre-build marian-decoder for the correct architecture.

### full
Builds a docker for CPU & GPU usage. Builds a copy of a CPU-only and GPU-only binary for their respective architectures.

## Notes
When building, `model/` files are compressed to `/model/model.tar.xz`. At launch, these are uncompressed to `/extracted-model`. See `run.sh` for an example of this behaviour.
