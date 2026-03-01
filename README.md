# 🦀 rust-ai-rules-template

Rust 프로젝트 시작 시 AI 도구(Claude, Cursor, GitHub Copilot 등)에 일관된 작업 품질을 부여하는 **도메인별 Rules 템플릿**.

---

## 📁 구조

```
rust-ai-rules-template/
├── _common/                        # 모든 도메인 공통 베이스 (각 도메인 파일에 포함됨)
│   └── base.rules.md
│
├── web-axum/                       # 풀스택 웹 (Axum + SQLx + Tokio)
│   ├── .cursorrules                → Cursor / Windsurf
│   ├── CLAUDE.md                   → Claude Code (자동 읽힘)
│   └── .github/
│       └── copilot-instructions.md → GitHub Copilot
│
├── embedded/                       # 임베디드 (Embassy / RTIC / no_std)
│   ├── .cursorrules
│   ├── CLAUDE.md
│   └── .github/
│       └── copilot-instructions.md
│
├── systems-cli/                    # 시스템 도구 / CLI / 데몬
│   ├── .cursorrules
│   ├── CLAUDE.md
│   └── .github/
│       └── copilot-instructions.md
│
└── scripts/
    └── init.sh                     # 도메인 선택 → 새 프로젝트에 자동 복사
```

---

## 🚀 사용법

### 방법 1: init.sh 스크립트 (추천)

```bash
# 이 레포 클론
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
# 예: 웹 프로젝트
cp web-axum/.cursorrules       ~/projects/my-api/
cp web-axum/CLAUDE.md          ~/projects/my-api/
cp -r web-axum/.github/        ~/projects/my-api/
```

### 방법 3: GitHub Template Repository

GitHub에서 이 레포를 **Template Repository**로 설정하면,
"Use this template" 버튼으로 새 레포 생성 시 모든 파일이 자동으로 포함됨.
(불필요한 도메인 폴더는 삭제)

---

## 🛠️ 플랫폼별 적용 위치

| 플랫폼 | 파일 위치 | 비고 |
|--------|-----------|------|
| **Cursor / Windsurf** | `.cursorrules` (프로젝트 루트) | 자동 감지 |
| **Claude Code** | `CLAUDE.md` (프로젝트 루트) | 자동 읽힘 |
| **GitHub Copilot** | `.github/copilot-instructions.md` | 레포 루트 |
| **Claude Projects** | Project Instructions에 붙여넣기 | UI 설정 |

> **핵심**: 각 플랫폼은 자기 파일만 읽으므로 모두 공존해도 간섭 없음.

---

## 📋 도메인 설명

| 도메인 | 대상 | 주요 스택 |
|--------|------|----------|
| `web-axum` | REST API, SSR 웹앱 | Axum, SQLx, Tokio, Leptos |
| `embedded` | MCU 펌웨어, IoT | Embassy, RTIC, defmt, embedded-hal |
| `systems-cli` | CLI 도구, 데몬, OS 레벨 | clap, Rayon, Tokio, tracing |

---

## 🔄 업데이트

Rules를 수정하면 `_common/base.rules.md` 또는 각 도메인 파일을 직접 수정.

---

## 📝 라이선스

MIT
