#!/bin/bash
set -e

# 该脚本在 Docker 容器内执行，/build 目录已挂载宿主项目目录
cd /build
bash raphael-kernel_build.sh "$@"
