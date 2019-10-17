# Using gcc:7.4.0 as base image
FROM gcc:7.4.0

# Install linux packages
RUN apt-get update && \
    apt-get install -y \
        wget \
        python3 \
        python3-pip \
        cmake \
        julia

# Install powershell
WORKDIR /powershell
RUN wget https://github.com/PowerShell/PowerShell/releases/download/v6.2.3/powershell-6.2.3-linux-x64.tar.gz \
    && tar -xzf powershell-6.2.3-linux-x64.tar.gz \
    # Create a symlink to pwsh
    && ln -s /powershell/pwsh /usr/local/bin \
    && rm powershell-6.2.3-linux-x64.tar.gz

# Install dotnet 2.1
RUN wget https://dot.net/v1/dotnet-install.sh \
    && chmod +x dotnet-install.sh \
    && ./dotnet-install.sh -c 2.1 \
    # Create a symlink to dotnet
    && ln -s ~/.dotnet/dotnet /usr/local/bin

WORKDIR /adb
# Copy code to /adb (.dockerignore exclude some files)
COPY . .

# Setting workdir for building the project
WORKDIR /adb/build

# Configure and build
# Optional cmake key: -DCUDA=ON
RUN cmake -DCMAKE_BUILD_TYPE=release .. \
    && make

WORKDIR /adb/ADBench
# make wrapper script executable
RUN chmod +x run-wrapper.sh

ENTRYPOINT ["./run-wrapper.sh"]