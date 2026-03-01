#!/usr/bin/env bash
# mcp-setup.sh — MCP config 파일을 플랫폼별 위치에 복사
#
# 사용법:
#   ./scripts/mcp-setup.sh <platform> [project-dir]
#
# 플랫폼:
#   cursor        → <project>/.cursor/mcp.json
#   claude-code   → <project>/.claude/settings.json
#   antigravity   → <project>/.gemini/antigravity/mcp_config.json
#   windsurf      → ~/.codeium/windsurf/mcp_config.json (글로벌)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
MCP_CONFIGS="$REPO_ROOT/mcp/configs"

PLATFORM="${1:-}"
PROJECT_DIR="${2:-$(pwd)}"

if [[ -z "$PLATFORM" ]]; then
  echo "Usage: $0 <platform> [project-dir]"
  echo "Platforms: cursor | claude-code | antigravity | windsurf"
  exit 1
fi

case "$PLATFORM" in
  cursor)
    DEST="$PROJECT_DIR/.cursor/mcp.json"
    mkdir -p "$(dirname "$DEST")"
    # JSON 주석(// ...) 제거 후 복사 (JSON은 주석 불가)
    grep -v '^\/\/' "$MCP_CONFIGS/cursor.json" > "$DEST"
    echo "✅  Cursor MCP config → $DEST"
    ;;

  claude-code)
    DEST="$PROJECT_DIR/.claude/settings.json"
    mkdir -p "$(dirname "$DEST")"
    grep -v '^\/\/' "$MCP_CONFIGS/claude-code.json" > "$DEST"
    echo "✅  Claude Code MCP config → $DEST"
    ;;

  antigravity)
    DEST="$PROJECT_DIR/.gemini/antigravity/mcp_config.json"
    mkdir -p "$(dirname "$DEST")"
    grep -v '^\/\/' "$MCP_CONFIGS/antigravity.json" > "$DEST"
    echo "✅  Antigravity MCP config → $DEST"
    ;;

  windsurf)
    DEST="$HOME/.codeium/windsurf/mcp_config.json"
    mkdir -p "$(dirname "$DEST")"
    grep -v '^\/\/' "$MCP_CONFIGS/windsurf.json" > "$DEST"
    echo "✅  Windsurf MCP config (global) → $DEST"
    ;;

  *)
    echo "Unknown platform: $PLATFORM"
    echo "Supported: cursor | claude-code | antigravity | windsurf"
    exit 1
    ;;
esac

echo ""
echo "⚠️  Docker MCP 스택이 실행 중이어야 합니다:"
echo "   cd $(realpath "$REPO_ROOT")/mcp && docker compose up -d"
