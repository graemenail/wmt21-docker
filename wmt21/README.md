# wmt21-docker

## !
Pre-built `marian-decoder` should be built for the correct architecture:
  - **CPU:** `icelake-server`
  - **GPU:** `znver2`

## Variants
### basic-gpu
Builds a docker for GPU usage.

Requirements:
  1. Provide a **statically compiled** `marian-decoder`, this will be placed at `/marian-decoder` inside the docker.
  2. Necessary model files to be put inside `model`.
  3. Adapt `run.sh` to suit your needs for the different hardware/tasks.

Once prepared, you can invoke building via `make` - please edit `IMAGE` to specify your image name.

### basic-cpu
Builds a docker for CPU usage.

Requirements:
  1. Provide a **statically compiled** `marian-decoder`, this will be placed at `/marian-decoder` inside the docker.
  2. Necessary model files to be put inside `model`.
  3. Adapt `run.sh` to suit your needs for the different hardware/tasks.

Once prepared, you can invoke building via `make` - please edit `IMAGE` to specify your image name.

### full
Builds a docker for CPU & GPU usage. Builds a copy of a CPU-only and GPU-only binary for their respective architectures.

Requirements:
  1. Necessary model files to be put inside `model`.
  2. Adapt `run.sh` to suit your needs for the different hardware/tasks.

You can build this from inside its directory via:
```shell
docker build -t image_name .
```

Relevant `--build-args` that influence compilation are:
```shell
# CPU
ARG CPU_BUILD="ON"
ARG MARIAN_CPU_REPO="https://github.com/marian-nmt/marian-dev.git"
ARG MARIAN_CPU_REF="wngt2021maxi"
# GPU
ARG GPU_BUILD="ON"
ARG MARIAN_GPU_REPO="https://github.com/XapaJIaMnu/marian-dev.git"
ARG MARIAN_GPU_REF="8bitgpu_maxi"
```

You may need to invalidate the cache to pull new commits in, to do so run docker build  with `--no-cache`.

## Notes

### Docker Paths
 - `/model` - compressed version of your model
 - `/extracted-model` - uncompressed of your model
 - `/run.sh` - the run script that will be called during evaluation
 - `/wmt` - a **reserved** path not to be used

### Writing a `/run.sh`
Each variant contains a sample `run.sh` as a starting to point to adapt to your own needs.

At the top of these samples `MARIAN_OPTIONS` is used to set global options. There are two switch statements, one controlling hardware-specific options and the other controlling task-specific options. For the basic variants, `BINARY` will probably be `marian-decoder`; however, in the _full_ variant, there are separate binaries for GPU and CPU evaluation.

At the end of the script we call the binary with the options via:
```shell
/$BINARY ${MARIAN_OPTIONS[@]}
```

### Model Compression
When building, `model/` files are compressed to `/model/model.tar.xz`. At launch, these are uncompressed to `/extracted-model`. See `run.sh` for an example of this behaviour.
