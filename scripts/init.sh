#!/usr/bin/env bash
# init.sh — 도메인 Rules + MCP config를 새 프로젝트에 적용
#
# 사용법:
#   ./scripts/init.sh <domain> <project-path> [mcp: yes|no]
#   ./scripts/init.sh web-axum ~/projects/my-api
#   ./scripts/init.sh web-axum ~/projects/my-api yes   # MCP config도 함께
#   ./scripts/init.sh embedded ~/projects/my-firmware
#   ./scripts/init.sh systems-cli ~/projects/my-tool

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"

DOMAIN="$1"
PROJECT="$2"
INCLUDE_MCP="${3:-no}"

if [ -z "$DOMAIN" ] || [ -z "$PROJECT" ]; then
  echo "Usage: $0 <domain> <project-path> [mcp: yes|no]"
  echo "  Domains: web-axum, embedded, systems-cli"
  exit 1
fi

if [ ! -d "$SCRIPT_DIR/$DOMAIN" ]; then
  echo "Error: domain not found: $DOMAIN"
  echo "Available: web-axum, embedded, systems-cli"
  exit 1
fi

if [ ! -d "$PROJECT" ]; then
  echo "Error: project directory not found: $PROJECT"
  exit 1
fi

echo "=== Rust AI Rules 적용 ==="
echo "도메인: $DOMAIN → $PROJECT"

# Rules 파일 복사
echo "[1/3] Rules 파일 복사"
cp "$SCRIPT_DIR/$DOMAIN/CLAUDE.md" "$PROJECT/"
cp "$SCRIPT_DIR/$DOMAIN/.cursorrules" "$PROJECT/"
mkdir -p "$PROJECT/.gemini"
cp -r "$SCRIPT_DIR/$DOMAIN/.gemini/" "$PROJECT/.gemini/"
mkdir -p "$PROJECT/.github"
cp "$SCRIPT_DIR/$DOMAIN/.github/copilot-instructions.md" "$PROJECT/.github/"

# Agents Skills 복사 (Antigravity + 호환 플랫폼)
echo "[2/3] Agent Skills 복사"
mkdir -p "$PROJECT/.agents"
cp -r "$SCRIPT_DIR/$DOMAIN/.agents/" "$PROJECT/.agents/"

# MCP config (선택)
if [ "$INCLUDE_MCP" = "yes" ]; then
  echo "[3/3] MCP config 복사"
  "$SCRIPT_DIR/scripts/mcp-setup.sh" "$PROJECT" all
else
  echo "[3/3] MCP config 건너뜀 (포함하려면 마지막 인자에 'yes' 추가)"
fi

echo ""
echo "완료! 추가로 필요한 것:"
echo "  1. AGENT_LOG.md 파일 생성 (에이전트 작업 기록용)"
echo "     touch $PROJECT/AGENT_LOG.md"
if [ "$INCLUDE_MCP" != "yes" ]; then
  echo "  2. MCP 설정이 필요하면:"
  echo "     ./scripts/mcp-setup.sh $PROJECT all"
fi
