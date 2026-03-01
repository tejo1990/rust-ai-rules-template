# AI-Augmented TDD (Test-Driven Development)

TDD와 AI를 조합할 때 가장 강력한 패턴을 정의한다.
기본 원칙: **AI는 구현을 빠르게 생성하지만, 인간은 테스트로 의도를 선언한다.**

---

## 핵심 사이클 (AI-TDD Loop)

```
1. SPEC    → 인간(또는 AI)이 테스트로 의도를 선언
2. RED     → cargo test 실패 확인
3. GREEN   → AI가 최소 구현으로 통과시킴
4. REFACTOR→ AI가 리팩터 제안 → 인간이 검토
5. COMMIT  → 테스트와 구현을 함께 커밋
```

**AI 없이**: 인간이 RED→GREEN→REFACTOR 모두 담당 → 느림  
**AI 조합**: 인간이 테스트(의도)를 작성 → AI가 GREEN 달성 → 인간이 리팩터 검토  
→ 속도는 AI, 의도의 정확성은 인간이 담당하는 분업

---

## AI와 TDD 조합 시 규칙

### 테스트 먼저 (Red First)
- AI에게 구현을 먼저 요청하지 않는다.
  항상 "이 테스트를 통과하는 구현을 작성해줘" 형태로 요청한다.
- 테스트가 없는 구현 PR은 리뷰를 통과하지 못한다.
- AI가 테스트도 함께 생성할 때: 테스트를 먼저 보여달라고 요청하고,
  테스트가 의도에 맞는지 확인 후 구현을 요청한다.

### 테스트는 인간이 소유
- AI가 생성한 테스트는 반드시 인간이 검토한다.
- 테스트가 구현 세부사항을 검증하는지(나쁨) vs 행동을 검증하는지(좋음) 확인.
- `#[test]`에 `// AI-generated: review required` 주석을 붙이고
  검토 후 제거하는 관행을 유지한다.

### 테스트 명명 규칙
```rust
// 패턴: <대상>_<조건>_<기대결과>
#[test]
fn parse_empty_input_returns_error() { ... }

#[test]
fn user_service_create_with_duplicate_email_fails() { ... }

#[test]
fn cache_get_after_ttl_expiry_returns_none() { ... }
```

### AI에게 테스트 생성 요청 시 프롬프트 패턴
```
"다음 함수의 테스트를 먼저 작성해줘.
구현은 아직 작성하지 말고, 실패하는 테스트만.
다음 케이스를 커버해야 해: [케이스 목록]"
```

---

## AI와 조합이 특히 효과적인 패러다임

### 1. ATDD (Acceptance TDD)
- 기능 요구사항을 실행 가능한 인수 테스트로 먼저 정의.
- AI가 인수 테스트 → 단위 테스트 → 구현 순서로 생성.
- 도구: `cucumber-rs`, `assert_cmd` (CLI), `reqwest` 기반 E2E.

### 2. Property-Based Testing
- 경계값, 특수 케이스를 인간이 놓치는 경우가 많음.
- AI에게 "이 함수의 불변식(invariant)을 proptest로 작성해줘" 요청.
- AI는 도메인 규칙으로부터 속성(property)을 잘 도출함.
```rust
// AI가 잘 생성하는 proptest 패턴
proptest! {
    #[test]
    fn encode_decode_roundtrip(input in any::<Vec<u8>>()) {
        let encoded = encode(&input);
        let decoded = decode(&encoded).unwrap();
        prop_assert_eq!(input, decoded);
    }
}
```

### 3. Mutation Testing (돌연변이 테스트)
- 구현에 고의적 버그를 심어 테스트가 잡아내는지 확인.
- 도구: `cargo-mutants`
- AI에게 "이 테스트의 돌연변이 생존율을 낮추려면 어떤 추가 테스트가 필요해?" 질문.
- 테스트 품질을 정량화하는 가장 효과적인 방법.

### 4. Contract Testing (계약 테스트)
- 서비스 간 API 계약을 테스트로 표현.
- AI가 스펙 문서 → 계약 테스트 자동 생성에 강함.
- 도구: `pact-rust` 또는 단순 trait 기반 계약.

### 5. Test Archaeology (AI로 레거시 분석)
- 기존 코드에 테스트가 없을 때: AI에게 코드를 분석시켜
  "이 코드의 의도된 행동을 설명하고 테스트를 역설계해줘" 요청.
- 리팩터 전 골든 마스터 테스트 생성에 효과적.

---

## 전용 Test Agent 사용 패턴

도구가 sub-agent를 지원할 때 (Antigravity, Claude Code):

```
Test Agent 역할 선언:
"너는 Test Agent야. 오직 테스트 코드만 작성한다.
구현 파일(src/*)은 읽을 수 있지만 수정하지 않는다.
테스트 파일(tests/*, src/**/#[cfg(test)])만 수정한다."
```

**권장 분리 패턴:**
- `Implementation Agent`: `src/` (테스트 외 구현 파일)
- `Test Agent`: `tests/`, `src/**/#[cfg(test)]` 블록

두 에이전트가 같은 파일을 동시에 수정하지 않도록
파일 소유권을 명확히 선언한다.

---

## 테스트 커버리지 기준

| 레이어 | 최소 커버리지 | 권장 |
|--------|--------------|------|
| 도메인 로직 / 비즈니스 규칙 | 90% | 100% |
| Repository / DB 레이어 | 80% | 90% |
| Handler / Controller | 70% | 80% |
| CLI 서브커맨드 | 80% | 90% |
| 임베디드 드라이버 (host-side) | 60% | 80% |

```bash
# 커버리지 측정
cargo install cargo-tarpaulin
cargo tarpaulin --out Html --output-dir coverage/
```

---

## 테스트 속도 관리

- 단위 테스트: < 1초 (개별), < 30초 (전체)
- 통합 테스트: < 5분 (CI 기준)
- 느린 테스트에 `#[ignore]`를 붙이고 CI에서 별도 실행:
```bash
cargo test                    # 빠른 테스트
cargo test -- --ignored       # 느린 테스트 (CI 별도 스텝)
```
- AI가 생성하는 테스트가 불필요한 sleep이나 I/O를 포함하는지 확인.
  포함 시 mock 또는 `tokio::time::pause()`로 대체 요청.
