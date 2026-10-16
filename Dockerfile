FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Miniforge (Conda)
ARG TARGETARCH
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        ARCH="x86_64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        ARCH="aarch64"; \
    else \
        echo "Unsupported architecture: $TARGETARCH" && exit 1; \
    fi && \
    wget -q "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-${ARCH}.sh" \
         -O /tmp/miniforge.sh && \
    bash /tmp/miniforge.sh -b -p /opt/conda && \
    rm /tmp/miniforge.sh

# Add Conda to PATH
ENV PATH="/opt/conda/bin:${PATH}"
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=/usr/local/cuda/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}

# Create a Conda environment
RUN conda create -y -n excellgen python=3.11 && \
    conda clean -afy

# Make the environment active for subsequent commands
ENV PATH="/opt/conda/envs/excellgen/bin:${PATH}"

# Copy application code
COPY . /workspace/excellgen

WORKDIR /workspace/excellgen

ENV GCA_ROOT=/workspace/excellgen/deps/fast-gca

RUN git submodule update --init --recursive

RUN conda init

RUN conda run -n excellgen pip uninstall -y setuptools && \
    conda run -n excellgen pip install setuptools==64

RUN conda run -n excellgen pip install torch==2.1.2 torchvision==0.16.2 torchaudio==2.1.2 --index-url https://download.pytorch.org/whl/cu118
RUN conda run -n excellgen pip install "numpy<2"

RUN conda install -n excellgen -c conda-forge colmap

RUN apt-get update && apt install -y ffmpeg build-essential python3-dev libopenblas-dev

# Replace MinkowskiEngine with our implmentation
RUN rm -rf deps/MinkowskiEngine
RUN git clone https://github.com/clementjambon/MinkowskiEngine.git deps/MinkowskiEngine

WORKDIR /workspace/excellgen/deps/MinkowskiEngine

RUN MAX_JOBS=4 conda run -n excellgen python setup.py install

WORKDIR /workspace/excellgen

RUN conda install -c conda-forge libstdcxx-ng
RUN apt install -y xorg-dev libglu1-mesa-dev freeglut3-dev mesa-common-dev

RUN conda run -n excellgen pip install --no-index torch-scatter -f https://pytorch-geometric.com/whl/torch-2.1.2+cu118.html

RUN conda run -n excellgen pip install -r requirements.txt

RUN conda run -n excellgen pip install --no-deps -e deps/polyscope-py

RUN conda run -n excellgen pip install -e .

# Set entrypoint
ENTRYPOINT ["/bin/bash"]

