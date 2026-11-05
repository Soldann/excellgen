#!/bin/bash
docker buildx build -t excellgen:latest . 2>&1 | tee docker_log.txt
