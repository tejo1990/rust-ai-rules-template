#!/usr/bin/env bash
# mcp-setup.sh — AI 플랫폼별 MCP config 자동 배포
#
# 사용법:
#   ./scripts/mcp-setup.sh <project-path> <platform>
#   ./scripts/mcp-setup.sh ~/projects/my-api all        # 모든 플랫폼
#   ./scripts/mcp-setup.sh ~/projects/my-api cursor     # Cursor만
#   ./scripts/mcp-setup.sh ~/projects/my-api antigravity
#
# 전제: mcp/docker-compose.yml이 실행 중이어야 함

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
MCP_CONFIGS="$SCRIPT_DIR/mcp/configs"

PROJECT="$1"
PLATFORM="${2:-all}"

if [ -z "$PROJECT" ]; then
  echo "Usage: $0 <project-path> [platform: all|claude|cursor|antigravity|windsurf]"
  exit 1
fi

if [ ! -d "$PROJECT" ]; then
  echo "Error: project directory not found: $PROJECT"
  exit 1
fi

setup_claude() {
  echo "  → Claude Code"
  mkdir -p "$PROJECT/.claude"
  cp "$MCP_CONFIGS/claude-code.json" "$PROJECT/.claude/settings.json"
}

setup_cursor() {
  echo "  → Cursor"
  mkdir -p "$PROJECT/.cursor"
  cp "$MCP_CONFIGS/cursor.json" "$PROJECT/.cursor/mcp.json"
}

setup_antigravity() {
  echo "  → Google Antigravity"
  mkdir -p "$PROJECT/.gemini/antigravity"
  cp "$MCP_CONFIGS/antigravity.json" "$PROJECT/.gemini/antigravity/mcp_config.json"
}

setup_windsurf() {
  echo "  → Windsurf"
  mkdir -p "$PROJECT/.windsurf"
  cp "$MCP_CONFIGS/windsurf.json" "$PROJECT/.windsurf/mcp.json"
}

echo "MCP config 설정: $PROJECT"

case "$PLATFORM" in
  all)
    setup_claude
    setup_cursor
    setup_antigravity
    setup_windsurf
    ;;
  claude|claude-code)
    setup_claude ;;
  cursor)
    setup_cursor ;;
  antigravity)
    setup_antigravity ;;
  windsurf)
    setup_windsurf ;;
  *)
    echo "Unknown platform: $PLATFORM"
    exit 1
    ;;
esac

echo ""
echo "완료! MCP 서버가 실행 중인지 확인:"
echo "  cd $(dirname $SCRIPT_DIR)/mcp && docker compose ps"
echo ""
echo "서버가 꺼져 있다면:"
echo "  cd $(dirname $SCRIPT_DIR)/mcp && docker compose up -d"
