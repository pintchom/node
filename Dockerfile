FROM ubuntu:24.04

USER root
WORKDIR /root

# Install dependencies
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl ca-certificates gnupg dirmngr \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create required directories
RUN mkdir -p /root/hl/data /root/hl/tmp/shell_rs_out

# Configure for mainnet
RUN echo '{"chain": "Mainnet"}' > /root/visor.json

# Import Hyperliquid's GPG key and trust it
RUN curl -fsSL https://raw.githubusercontent.com/hyperliquid-dex/node/refs/heads/main/pub_key.asc \
    | gpg --import --batch --yes \
    && gpg --list-keys \
    && echo -e "5\ny\n" | gpg --command-fd 0 --expert --edit-key "CF2C2EA3DC3E8F042A55FB6503254A9349F1820B" trust quit || true

# Download hl-visor for mainnet
RUN curl -fsSL https://binaries.hyperliquid.xyz/Mainnet/hl-visor -o /root/hl-visor \
    && chmod +x /root/hl-visor

# Create a startup script to handle potential GPG issues and enable trade writing
RUN echo '#!/bin/bash\n\
    # Try to run hl-visor with trade writing enabled, if GPG fails, try to fix and retry\n\
    /root/hl-visor run-non-validator --write-fills --replica-cmds-style recent-actions || {\n\
    echo "First attempt failed, trying to fix GPG trust..."\n\
    echo -e "5\ny\n" | gpg --command-fd 0 --expert --edit-key "CF2C2EA3DC3E8F042A55FB6503254A9349F1820B" trust quit 2>/dev/null || true\n\
    echo "Retrying hl-visor..."\n\
    /root/hl-visor run-non-validator --write-fills --replica-cmds-style recent-actions\n\
    }' > /root/start.sh && chmod +x /root/start.sh

# Expose ports
EXPOSE 4001 4002

# Use the startup script
ENTRYPOINT ["/root/start.sh"]
