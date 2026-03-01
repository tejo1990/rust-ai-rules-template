# 🦀 rust-ai-rules-template

Rust 프로젝트 시작 시 AI 도구(Claude, Cursor, GitHub Copilot, **Google Antigravity** 등)에
일관된 작업 품질과 **에이전트 워크플로우**를 부여하는 **도메인별 Rules 템플릿**.

---

## 📁 구조

```
rust-ai-rules-template/
│
├── _common/
│   ├── base.rules.md          # 공통 베이스 (모든 도메인 파일에 포함됨)
│   └── agent.rules.md         # Agentic Workflow 섹션 (독립 참조용)
│
├── web-axum/                  # 풀스택 웹 (Axum + SQLx + Tokio)
│   ├── CLAUDE.md              → Claude Code (자동 읽힘)
│   ├── .cursorrules           → Cursor / Windsurf
│   ├── .gemini/GEMINI.md      → Google Antigravity (project rules)
│   ├── .agents/skills/
│   │   └── rust-web-axum/
│   │       └── SKILL.md       → Antigravity Skills (lazy-load)
│   └── .github/
│       └── copilot-instructions.md  → GitHub Copilot
│
├── embedded/                  # 임베디드 (Embassy / RTIC / no_std)
│   ├── CLAUDE.md
│   ├── .cursorrules
│   ├── .gemini/GEMINI.md
│   ├── .agents/skills/
│   │   └── rust-embedded/
│   │       └── SKILL.md
│   └── .github/
│       └── copilot-instructions.md
│
├── systems-cli/               # 시스템 도구 / CLI / 데몬
│   ├── CLAUDE.md
│   ├── .cursorrules
│   ├── .gemini/GEMINI.md
│   ├── .agents/skills/
│   │   └── rust-systems-cli/
│   │       └── SKILL.md
│   └── .github/
│       └── copilot-instructions.md
│
└── scripts/
    └── init.sh                # 도메인 선택 → 새 프로젝트에 자동 복사
```

---

## 🛠️ 플랫폼별 적용 위치

| 플랫폼 | 파일 위치 | 비고 |
|--------|-----------|------|
| **Claude Code** | `CLAUDE.md` (프로젝트 루트) | 자동 읽힘 |
| **Cursor / Windsurf** | `.cursorrules` (프로젝트 루트) | 자동 감지 |
| **Google Antigravity** | `.gemini/GEMINI.md` (프로젝트 루트) | Project Rules |
| **Google Antigravity** | `.agents/skills/<name>/SKILL.md` | 필요 시 lazy-load |
| **GitHub Copilot** | `.github/copilot-instructions.md` | 레포 루트 |
| **Claude Projects** | Project Instructions에 붙여넣기 | UI 설정 |

> 각 플랫폼은 자기 파일만 읽으므로 모두 공존해도 간섭 없음.

---

## 🤖 Agentic Workflow 개요

모든 도메인 파일에 **`## Agentic Workflow`** 섹션이 포함되어 있어,
에이전트가 자율적으로 작업할 때 다음을 보장:

- **계획 우선**: 코드 작성 전 Implementation Plan 생성
- **서브에이전트 분리**: 레이어/모듈 경계로 파일 소유권 명확히 선언
- **단계별 검증**: `cargo check` + `cargo test` 통과 후 다음 단계 진행
- **메모리 관리**: `AGENT_LOG.md`에 결정사항·진행상황 기록
- **스코프 규율**: 현재 태스크 외 리팩터 금지

### Antigravity Skills (고유 기능)

Antigravity의 **Skills**는 해당 키워드가 감지될 때만 context에 로드되는
lazy-loading 지식 패키지야. 각 도메인의 `.agents/skills/` 폴더에 위치.

```
# 예: "embassy"가 태스크에 언급되면 rust-embedded SKILL.md 자동 로드
# Agent Manager에서 코드 패턴 + Verification Checklist 즉시 사용 가능
```

---

## 🚀 사용법

### 방법 1: init.sh 스크립트 (추천)

```bash
# 이 레포 클론 (한 번만)
git clone https://github.com/tejo1990/rust-ai-rules-template.git
cd rust-ai-rules-template
chmod +x scripts/init.sh

# 새 프로젝트에 rules 적용
./scripts/init.sh web-axum ~/projects/my-api
./scripts/init.sh embedded ~/projects/my-firmware
./scripts/init.sh systems-cli ~/projects/my-tool
```

### 방법 2: 수동 복사

```bash
# 예: 웹 프로젝트 (모든 플랫폼 파일 한 번에)
cp web-axum/CLAUDE.md          ~/projects/my-api/
cp web-axum/.cursorrules       ~/projects/my-api/
cp -r web-axum/.gemini/        ~/projects/my-api/
cp -r web-axum/.agents/        ~/projects/my-api/
cp -r web-axum/.github/        ~/projects/my-api/
```

---

## 📋 도메인 설명

| 도메인 | 대상 | 주요 스택 |
|--------|------|----------|
| `web-axum` | REST API, SSR 웹앱 | Axum, SQLx, Tokio, Leptos |
| `embedded` | MCU 펌웨어, IoT | Embassy, RTIC, defmt, embedded-hal |
| `systems-cli` | CLI 도구, 데몬, OS 레벨 | clap, Rayon, Tokio, tracing |

---

## 📝 라이선스

MIT
