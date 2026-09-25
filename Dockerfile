# Build stage: compiles the release binary.
FROM rust:1.88-slim-bookworm AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Pre-build dependencies against a stub main.rs so they are cached in their own layer.
# benches/ is required because Cargo.toml declares a [[bench]] target; without it the
# manifest fails to parse and this step silently caches nothing.
COPY Cargo.toml Cargo.lock* ./
COPY benches ./benches
RUN mkdir src && echo 'fn main() {}' > src/main.rs && \
    cargo build --release 2>/dev/null || true && \
    rm -rf src

COPY . .
# COPY keeps the original source mtimes, which can predate the stub build above;
# touching main.rs forces Cargo to rebuild the real crate instead of reusing the stub.
RUN touch src/main.rs && cargo build --release && strip target/release/telemt

# Runtime stage: minimal Debian image with the stripped binary and CA certificates.
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -r -s /usr/sbin/nologin telemt

WORKDIR /app

COPY --from=builder /build/target/release/telemt /app/telemt
COPY config.toml /app/config.toml

RUN chown -R telemt:telemt /app
USER telemt

EXPOSE 443
EXPOSE 9090

ENTRYPOINT ["/app/telemt"]
CMD ["config.toml"]
