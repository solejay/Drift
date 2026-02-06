# Build stage
FROM swift:5.9-jammy as builder

WORKDIR /app

# Copy package files first for better caching
COPY Package.swift ./
COPY Package.resolved* ./
RUN swift package resolve

# Copy source and build
COPY Sources Sources
RUN mkdir -p Tests/AppTests
RUN swift build -c release --static-swift-stdlib --target App

# Runtime stage
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libcurl4 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/.build/release/App ./

EXPOSE 8080

ENTRYPOINT ["./App"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
