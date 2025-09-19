# Stage to fetch and prepare Nextcloud client
FROM jlesage/baseimage-gui:debian-12-v4.9 AS nextcloud-version

# Install build dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        git \
        build-essential \
        cmake \
        qtbase5-dev \
        qttools5-dev-tools \
        qtdeclarative5-dev \
        libqt5network5 \
        libqt5widgets5 \
        libqt5gui5 \
        libqt5core5a \
        zlib1g-dev \
        libssl-dev \
        libsqlite3-dev \
        wget \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/*

# Clone the latest Nextcloud client source
RUN git clone --depth 1 https://github.com/nextcloud/desktop.git /tmp/nextcloud && \
    cd /tmp/nextcloud && \
    mkdir build && cd build && \
    cmake .. && \
    make -j$(nproc)

# The resulting binary
RUN cp /tmp/nextcloud/build/client/nextcloud /usr/local/bin/nextcloud

# Final image
FROM jlesage/baseimage-gui:debian-12

# Copy the built binary from the previous stage
COPY --from=nextcloud-version /usr/local/bin/nextcloud /usr/local/bin/nextcloud

# Install runtime dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        libqt5network5 \
        libqt5widgets5 \
        libqt5gui5 \
        libqt5core5a \
        zlib1g \
        libssl1.1 \
        libsqlite3-0 \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/*

# Set default command
CMD ["/usr/local/bin/nextcloud"]
