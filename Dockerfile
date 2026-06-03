# 内核编译环境镜像
# 构建镜像（只需一次）：docker build -t kernel-builder .
# 编译内核：      docker run --rm -v $(pwd):/build kernel-builder bash /build/build-in-docker.sh <version>
FROM ubuntu:24.04

# 安装编译依赖 (与 GitHub Actions 工作流一致)
RUN apt-get update && apt-get install -y \
    build-essential \
    bc \
    flex \
    bison \
    p7zip-full \
    kmod \
    bash \
    cpio \
    binutils \
    tar \
    git \
    wget \
    dpkg-dev \
    libssl-dev \
    libelf-dev \
    python3 \
    rsync \
    debhelper-compat \
    libdw-dev \
    ccache \
    lsb-release \
    software-properties-common \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# 安装 LLVM/Clang 22
RUN wget -q https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    ./llvm.sh 22 && \
    rm llvm.sh

# 配置 ccache
ENV CCACHE_DIR=/ccache
ENV CCACHE_MAXSIZE=5G
ENV PATH="/usr/lib/ccache:${PATH}"

WORKDIR /build
