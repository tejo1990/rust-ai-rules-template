# MCP Docker Stack

Docker로 실행되는 로컬 MCP 서버 모음.
모든 AI 코딩 플랫폼(Claude Code, Cursor, Antigravity, Windsurf)이 **동일한 서버를 공유**.

---

## 서버 목록

| 서버 | 포트 | 역할 |
|------|------|------|
| `mcp-git` | 3001 | git 작업 (commit, diff, log) |
| `mcp-github` | 3002 | GitHub API (PR, Issues, Actions) |
| `mcp-filesystem` | 3003 | 파일 읽기/쓰기 (workspace 제한) |
| `mcp-thinking` | 3004 | Sequential Thinking (복잡한 계획 수립) |
| `mcp-memory` | 3005 | 세션 간 컨텍스트 유지 |
| `mcp-fetch` | 3006 | 웹 조회 (crates.io, docs.rs 등) |
| `mcp-postgres` | 3007 | PostgreSQL 쿼리 (web-axum 도메인) |
| `mcp-cargo` | 3008 | cargo 명령 안전 실행 (Rust 전용) |

---

## 빠른 시작

### 1. 환경변수 설정
```bash
cd mcp
cp .env.example .env
nano .env  # GITHUB_TOKEN, WORKSPACE_ROOT 설정
```

### 2. 서버 시작
```bash
# 기본 (embedded, systems-cli 도메인)
cd mcp && docker compose up -d

# web-axum 도메인 (PostgreSQL 포함)
cd mcp && docker compose --profile web up -d

# 상태 확인
docker compose ps
curl http://localhost:3001/health
```

### 3. 플랫폼별 config 복사

```bash
# Claude Code (글로벌)
cp configs/claude-code.json ~/.claude/claude_desktop_config.json

# Claude Code (프로젝트별)
mkdir -p ~/projects/my-api/.claude
cp configs/claude-code.json ~/projects/my-api/.claude/settings.json

# Cursor (프로젝트별)
mkdir -p ~/projects/my-api/.cursor
cp configs/cursor.json ~/projects/my-api/.cursor/mcp.json

# Antigravity
mkdir -p ~/projects/my-api/.gemini/antigravity
cp configs/antigravity.json ~/projects/my-api/.gemini/antigravity/mcp_config.json

# Windsurf (글로벌)
cp configs/windsurf.json ~/.codeium/windsurf/mcp_config.json
```

또는 `scripts/mcp-setup.sh` 스크립트 사용:
```bash
# 한 줄로 모든 플랫폼 설정
./scripts/mcp-setup.sh ~/projects/my-api all
```

---

## mcp-cargo 서버 (Rust 전용)

`cargo check`, `cargo test` 등을 MCP 도구로 에이전트가 직접 실행 가능.

```
# AI 에이전트가 사용 예시:
cargo_check_all()  → check + clippy + test 순서 실행
cargo_run(command="test", args="-- specific_test")  → 특정 테스트만
cargo_run(command="clippy", args="-- -D warnings")
```

**보안**: `ALLOWED_COMMANDS` 외 명령 실행 불가. `install`, `publish` 등 위험 명령 차단.

---

## Sequential Thinking 활용

`mcp-thinking` 서버는 복잡한 계획 수립에 효과적.

```
# 에이전트 프롬프트 예시:
"sequential-thinking 도구를 사용해서
 이 Axum API에 인증 미들웨어를 추가하는 계획을 먼저 세워줘.
 계획이 완료되면 구현을 시작해."
```

---

## 자동 시작 (macOS launchd)

```bash
# 시스템 시작 시 자동 실행
cat > ~/Library/LaunchAgents/com.rust-mcp.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" ...>
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.rust-mcp</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/local/bin/docker</string>
    <string>compose</string>
    <string>-f</string>
    <string>/path/to/rust-ai-rules-template/mcp/docker-compose.yml</string>
    <string>up</string>
    <string>-d</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
EOF
launchctl load ~/Library/LaunchAgents/com.rust-mcp.plist
```
