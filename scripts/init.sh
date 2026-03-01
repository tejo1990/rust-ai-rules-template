#!/usr/bin/env bash
# rust-ai-rules-template/scripts/init.sh
# 새 Rust 프로젝트에 도메인별 AI rules를 자동으로 복사
#
# 사용법:
#   ./scripts/init.sh <domain> <target-dir>
#
# 예시:
#   ./scripts/init.sh web-axum ~/projects/my-api
#   ./scripts/init.sh embedded ~/projects/my-firmware
#   ./scripts/init.sh systems-cli ~/projects/my-tool

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(dirname "$SCRIPT_DIR")"

DOMAINS=("web-axum" "embedded" "systems-cli")

usage() {
    echo "Usage: $0 <domain> <target-dir>"
    echo ""
    echo "Available domains:"
    for d in "${DOMAINS[@]}"; do
        echo "  - $d"
    done
    echo ""
    echo "Examples:"
    echo "  $0 web-axum ~/projects/my-api"
    echo "  $0 embedded ~/projects/my-firmware"
    echo "  $0 systems-cli ~/projects/my-tool"
    exit 1
}

if [[ $# -lt 2 ]]; then
    usage
fi

DOMAIN="$1"
TARGET="$2"

VALID=false
for d in "${DOMAINS[@]}"; do
    if [[ "$d" == "$DOMAIN" ]]; then
        VALID=true
        break
    fi
done

if [[ "$VALID" == false ]]; then
    echo "❌ Unknown domain: '$DOMAIN'"
    usage
fi

DOMAIN_DIR="$TEMPLATE_ROOT/$DOMAIN"

if [[ ! -d "$DOMAIN_DIR" ]]; then
    echo "❌ Domain directory not found: $DOMAIN_DIR"
    exit 1
fi

mkdir -p "$TARGET"

echo "🦀 Initializing Rust AI rules for domain: $DOMAIN"
echo "   Source : $DOMAIN_DIR"
echo "   Target : $TARGET"
echo ""

FILES_COPIED=0

copy_if_exists() {
    local src="$1"
    local dst_dir="$2"
    local filename
    filename="$(basename "$src")"

    if [[ -f "$src" ]]; then
        mkdir -p "$dst_dir"
        cp "$src" "$dst_dir/$filename"
        echo "  ✅ $dst_dir/$filename"
        ((FILES_COPIED++))
    fi
}

for f in "$DOMAIN_DIR"/*; do
    [[ -f "$f" ]] && copy_if_exists "$f" "$TARGET"
done

if [[ -d "$DOMAIN_DIR/.github" ]]; then
    copy_if_exists \
        "$DOMAIN_DIR/.github/copilot-instructions.md" \
        "$TARGET/.github"
fi

echo ""
echo "✨ Done! $FILES_COPIED file(s) copied to $TARGET"
echo ""
echo "Next steps:"
echo "  cd $TARGET"
echo "  cargo init  (or cargo new <name>)"
echo ""
