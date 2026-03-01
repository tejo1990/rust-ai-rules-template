# Rust 전용 MCP 서버: cargo 명령 안전 실행
# ALLOWED_COMMANDS 환경변수로 허용 명령 제한
FROM rust:1.82-slim

RUN apt-get update && apt-get install -y \
    curl nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# cargo 도구 설치
RUN cargo install cargo-size cargo-bloat 2>/dev/null || true

WORKDIR /app
COPY package.json ./
COPY server.js ./
RUN npm install

EXPOSE 3008
CMD ["node", "server.js"]
