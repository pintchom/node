FROM ubuntu:24.04

# Run as root to avoid permission issues with hl-visor
USER root
WORKDIR /root

# Install dependencies
RUN apt-get update -y && apt-get install -y curl gnupg ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /root/hl/data \
    && mkdir -p /root/hl/tmp/shell_rs_out

# Configure chain to testnet
RUN echo '{"chain": "Testnet"}' > /root/visor.json

# Import GPG public key
RUN curl -o /root/pub_key.asc https://raw.githubusercontent.com/hyperliquid-dex/node/refs/heads/main/pub_key.asc \
    && gpg --import /root/pub_key.asc

# Download and verify hl-visor binary
RUN curl -o /root/hl-visor https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor \
    && curl -o /root/hl-visor.asc https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor.asc \
    && gpg --verify /root/hl-visor.asc /root/hl-visor \
    && chmod +x /root/hl-visor

# Pre-download hl-node to prevent runtime download
RUN curl -o /root/hl-node https://binaries.hyperliquid-testnet.xyz/Testnet/hl-node \
    && curl -o /root/hl-node.asc https://binaries.hyperliquid-testnet.xyz/Testnet/hl-node.asc \
    && gpg --verify /root/hl-node.asc /root/hl-node \
    && chmod +x /root/hl-node

# Expose port 4001
EXPOSE 4001

# Run non-validator with only trade data
ENTRYPOINT ["/root/hl-visor", "run-non-validator", "--write-trades", "--replica-cmds-style", "recent-actions"]
