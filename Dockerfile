FROM ubuntu:24.04

# Run as root to match hl-visor expectations
USER root
WORKDIR /root

# Install dependencies
RUN apt-get update -y && apt-get install -y curl ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /root/hl/data \
    && mkdir -p /root/hl/tmp/shell_rs_out

# Configure chain to testnet
RUN echo '{"chain": "Testnet"}' > /root/visor.json

# Download binaries (skip GPG verification for now)
RUN curl -o /root/hl-visor https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor \
    && curl -o /root/hl-node https://binaries.hyperliquid-testnet.xyz/Testnet/hl-node \
    && chmod +x /root/hl-visor /root/hl-node

# Expose port 4001
EXPOSE 4001

# Run non-validator with only trade data
ENTRYPOINT ["/root/hl-visor", "run-non-validator", "--write-trades", "--replica-cmds-style", "recent-actions"]
