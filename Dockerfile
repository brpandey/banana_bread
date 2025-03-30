# Use multi-stage build
FROM messense/rust-musl-cross:x86_64-musl AS chef
ENV SQLX_OFFLINE=true
RUN cargo install cargo-chef
WORKDIR /banana_bread

FROM chef AS planner
# Copy source code from previous stage
COPY . .
# Generate info for caching dependencies stored in recipe.json
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /banana_bread/recipe.json recipe.json
# Build & cache dependencies
RUN cargo chef cook --release --target x86_64-unknown-linux-musl --recipe-path recipe.json
# Copy source code from previous stage
COPY . .
# Build application
RUN cargo build --release --target x86_64-unknown-linux-musl

# Create a new stage with a minimal image with just the binary, as we don't need the rust toolchain
FROM scratch
# Copy binary from previous stage
COPY --from=builder /banana_bread/target/x86_64-unknown-linux-musl/release/banana_bread /banana_bread
ENTRYPOINT ["/banana_bread"]
EXPOSE 3000
