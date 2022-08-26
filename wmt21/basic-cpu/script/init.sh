#!/bin/bash
if [[ -f /model/model.tar.xz ]]; then
  (mkdir /extracted-model && cd /extracted-model && tar xf /model/model.tar.xz)
fi

/bin/sh -c "$*"
