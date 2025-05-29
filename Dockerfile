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

# Configure for testnet
RUN echo '{"chain": "Testnet"}' > /root/visor.json

# Import Hyperliquid's GPG key and trust it
RUN curl -fsSL https://raw.githubusercontent.com/hyperliquid-dex/node/refs/heads/main/pub_key.asc \
    | gpg --import --batch --yes \
    && gpg --list-keys \
    && echo -e "5\ny\n" | gpg --command-fd 0 --expert --edit-key "CF2C2EA3DC3E8F042A55FB6503254A9349F1820B" trust quit || true

# Download hl-visor only (let it handle hl-node download and verification)
RUN curl -fsSL https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor -o /root/hl-visor \
    && chmod +x /root/hl-visor

# Create a startup script to handle potential GPG issues
RUN echo '#!/bin/bash\n\
    # Try to run hl-visor, if GPG fails, try to fix and retry\n\
    /root/hl-visor run-non-validator --write-trades --replica-cmds-style recent-actions || {\n\
    echo "First attempt failed, trying to fix GPG trust..."\n\
    echo -e "5\ny\n" | gpg --command-fd 0 --expert --edit-key "CF2C2EA3DC3E8F042A55FB6503254A9349F1820B" trust quit 2>/dev/null || true\n\
    echo "Retrying hl-visor..."\n\
    /root/hl-visor run-non-validator --write-trades --replica-cmds-style recent-actions\n\
    }' > /root/start.sh && chmod +x /root/start.sh

# Expose port
EXPOSE 4001

# Use the startup script
ENTRYPOINT ["/root/start.sh"]
