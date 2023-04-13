# Using nvidia/cuda:11.1.1-devel-ubuntu20.04 as base image
# CUDA version shoud be consistent with **/requirements-cuda.txt
FROM nvidia/cuda:11.1.1-devel-ubuntu20.04

# Install linux packages
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        wget \
        python3 \
        python3-pip \
        cmake \
        && rm -rf /var/lib/apt/lists/*

# Install julia
WORKDIR /utils/julia
RUN wget -q https://julialang-s3.julialang.org/bin/linux/x64/1.8/julia-1.8.5-linux-x86_64.tar.gz \
    && tar -xzf julia-1.8.5-linux-x86_64.tar.gz \
    # Create a symlink to julia
    && ln -s /utils/julia/julia-1.8.5/bin/julia /usr/local/bin \
    && rm julia-1.8.5-linux-x86_64.tar.gz

# Install powershell
WORKDIR /utils/powershell
RUN wget -q https://github.com/PowerShell/PowerShell/releases/download/v6.2.3/powershell-6.2.3-linux-x64.tar.gz \
    && tar -xzf powershell-6.2.3-linux-x64.tar.gz \
    # Create a symlink to pwsh
    && ln -s /utils/powershell/pwsh /usr/local/bin \
    && rm powershell-6.2.3-linux-x64.tar.gz

# Install dotnet 3.1
RUN wget -q https://dot.net/v1/dotnet-install.sh \
    && chmod +x dotnet-install.sh \
    && ./dotnet-install.sh -c 3.1 \
    # Create a symlink to dotnet
    && ln -s ~/.dotnet/dotnet /usr/local/bin

# upgrade pip to be sure that tf>=2.0 could be installed
RUN python3 -m pip install --upgrade pip

# Module for python packages installing
RUN python3 -m pip install pip setuptools>=41.0.0

WORKDIR /adb
# Copy code to /adb (.dockerignore exclude some files)
COPY . .

# Setting workdir for building the project
WORKDIR /adb/build

# Configure and build
RUN cmake -DCMAKE_BUILD_TYPE=release -DCUDA=ON .. \
    && make

WORKDIR /adb/ADBench
RUN sed -i 's/\r//' run-wrapper.sh \
    # make wrapper script executable
    && chmod +x run-wrapper.sh

ENTRYPOINT ["./run-wrapper.sh"]
