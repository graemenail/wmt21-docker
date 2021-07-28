#!/bin/bash
if [[ ! -d /extracted-model ]]; then
  (mkdir /extracted-model && cd /extracted-model && tar xf /model/model.tar.xz)
fi

/bin/sh -c "$*"
