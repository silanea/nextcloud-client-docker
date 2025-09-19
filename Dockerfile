# Stage 1: Build
FROM jlesage/baseimage-gui:debian-12 AS build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    cmake \
    build-essential \
    pkg-config \
    qtbase5-dev \
    qttools5-dev \
    libqt5network5 \
    libqt5sql5 \
    libqt5sql5-sqlite \
    libqt5webkit5-dev \
    libssl-dev \
    libsqlite3-dev \
    libfuse2 \
    wget \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Set build directory
WORKDIR /tmp/build

# Fetch the latest Nextcloud client source dynamically
RUN LATEST=$(wget -qO- https://api.github.com/repos/nextcloud/desktop/releases/latest | \
     grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') && \
    echo "Latest release: $LATEST" && \
    wget -O nextcloud-client.zip https://github.com/nextcloud/desktop/archive/refs/tags/$LATEST.zip && \
    unzip nextcloud-client.zip && \
    mv desktop-$LATEST nextcloud-client

# Build the client
WORKDIR /tmp/build/nextcloud-client
RUN mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make -j$(nproc) && make install

# Stage 2: Runtime
FROM jlesage/baseimage-gui:debian-12

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libqt5network5 \
    libqt5sql5 \
    libqt5sql5-sqlite \
    libqt5webkit5 \
    libssl1.1 \
    libsqlite3-0 \
    libfuse2 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy Nextcloud client from build stage
COPY --from=build /usr/local /usr/local

# Expose GUI if needed
ENV DISPLAY=:0

# Set default command
CMD ["/usr/local/bin/nextcloud"]
