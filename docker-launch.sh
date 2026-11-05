#!/bin/bash
docker run --rm -it \
    --gpus all \
    -v "$(pwd):/workspace/excellgen" \
    excellgen