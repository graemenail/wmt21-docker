.PHONY: all clean test-gpu test-cpu test

SHELL:=/bin/bash

# How to:
# 1. Make a copy of the entire directory
# 2. Change the IMAGE variable below
# 3. Copy a statically compiled marian-decoder to ./marian-decoder
# 4. Copy all model files to ./model/
# 6. Update /run.sh

IMAGE=wmt21_cpu

all: $(IMAGE).tar.gz

# Compress
%.tar.gz: %.image README.md
	sha512sum $< > $<.sha512sum
	tar zcvf $@ $< $<.sha512sum README.md

# Build Image
$(IMAGE).image: Dockerfile marian* run.sh init.sh model/
	docker image build -t $(IMAGE) .
	docker save $(IMAGE) > $@

test: test-cpu test-gpu

test-cpu: $(IMAGE).image
	docker load -i $<
	sacrebleu -t wmt19 -l en-de --echo src \
		| docker run -i --rm $(IMAGE) /run.sh CPU-1 throughput \
		| sacrebleu -t wmt19 -l en-de

test-gpu: $(IMAGE).image
	docker load -i $<
	sacrebleu -t wmt19 -l en-de --echo src \
		| docker run -i --rm --gpus device=0 $(IMAGE) /run.sh GPU throughput \
		| sacrebleu -t wmt19 -l en-de

clean:
	rm -f *.image *.sha512sum *.tar.gz
	docker rmi -f $(IMAGE)
