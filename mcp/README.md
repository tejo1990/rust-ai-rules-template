# MCP Docker Stack

어떤 AI 코딩 플랫폼에서든 **동일한 MCP 서버**를 Docker로 실행하고,
**플랫폼별 얇은 config 파일**로 연결하는 구조야.

## 구성 MCP 서버

| 서버 | 포트 | 역할 |
|------|------|------|
| filesystem | 3001 | 프로젝트 파일 읽기/쓰기 (워크스페이스 한정) |
| git | 3002 | git 조작 (commit, diff, log 등) |
| github | 3003 | GitHub API (PR, Issues, Actions) |
| memory | 3004 | 세션 간 컨텍스트 유지 (아키텍처 결정사항 등) |
| sequential-thinking | 3005 | 복잡한 멀티스텝 계획 수립 |
| fetch | 3006 | 외부 문서/crates.io/RFC 페이지 fetch |

## 빠른 시작

```bash
# 1. 환경변수 설정
cd mcp
cp .env.example .env
# .env 열어서 GITHUB_TOKEN, PROJECTS_ROOT 편집

# 2. Docker 스택 실행
docker compose up -d

# 3. 상태 확인
docker compose ps

# 4. 플랫폼별 config 복사 (한 번만)
./scripts/mcp-setup.sh cursor        # → .cursor/mcp.json
./scripts/mcp-setup.sh claude-code   # → .claude/settings.json
./scripts/mcp-setup.sh antigravity   # → .gemini/antigravity/mcp_config.json
./scripts/mcp-setup.sh windsurf      # → ~/.codeium/windsurf/mcp_config.json
```

## 플랫폼별 config 파일 위치

| 플랫폼 | config 복사 경로 | 비고 |
|--------|-----------------|------|
| **Cursor** | `<project>/.cursor/mcp.json` | 프로젝트별 |
| **Claude Code** | `<project>/.claude/settings.json` | 프로젝트별 |
| **Antigravity** | `<project>/.gemini/antigravity/mcp_config.json` | 프로젝트별 |
| **Windsurf** | `~/.codeium/windsurf/mcp_config.json` | 글로벌 |

> **핵심**: Docker 서버는 한 번만 올리면 모든 플랫폼이 같은 서버를 공유.
> 토큰/키는 `.env` 한 곳에서만 관리.

## 보안 주의사항

- `.env` 파일은 절대 git에 커밋하지 마 (`.gitignore`에 포함됨)
- `PROJECTS_ROOT` 밖의 경로는 filesystem MCP가 거부
- 모든 서버는 `127.0.0.1`(localhost)에만 바인딩 — 외부 접근 불가
- `GITHUB_TOKEN`은 최소 권한으로 생성 (repo + read:org)

## 스택 관리

```bash
# 중지
docker compose -f mcp/docker-compose.yml down

# 로그 확인
docker compose -f mcp/docker-compose.yml logs -f

# 특정 서버만 재시작
docker compose -f mcp/docker-compose.yml restart mcp-github

# memory 데이터 초기화
docker compose -f mcp/docker-compose.yml down -v
```

## init.sh 연동

`scripts/init.sh`로 도메인 rules를 복사할 때 MCP config도 함께 복사:

```bash
# 기존: rules만 복사
./scripts/init.sh web-axum ~/projects/my-api

# MCP config도 함께 복사 (--mcp 플래그)
./scripts/init.sh web-axum ~/projects/my-api --mcp cursor
./scripts/init.sh web-axum ~/projects/my-api --mcp claude-code
```
