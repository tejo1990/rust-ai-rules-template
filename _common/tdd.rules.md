# TDD + AI 개발 패러다임

## 왜 TDD+AI 조합이 강력한가

전통 TDD는 "사람이 테스트 → 사람이 구현" 사이클이야.
AI를 조합하면 사이클이 확장돼:

```
[사람] 요구사항 → 실패 테스트 작성 (또는 AI에게 테스트 초안 생성 위임)
[AI]   테스트를 통과하는 최소 구현 작성
[사람] 구현 검토 + 리팩터 지시
[AI]   리팩터 수행 (테스트는 계속 그린)
```

AI는 "테스트가 이미 존재하는 상황"에서 구현 품질이 극적으로 올라가.
테스트 = AI에게 주는 가장 정확한 spec.

---

## AI-TDD 사이클 (Rust)

### Phase 1: Spec → Test (Red)

**사람이 할 일:**
- 요구사항을 자연어로 기술
- 또는 직접 실패 테스트 작성

**AI에게 위임 가능한 부분:**
```
프롬프트 예시:
"다음 요구사항에 대한 실패 테스트를 작성해줘.
테스트가 컴파일은 되지만 실행 시 실패해야 해.
구현은 절대 건드리지 마.

요구사항: EmailAddress 타입은 @ 포함 여부와 도메인을 검증해야 한다."
```

**규칙:**
- 테스트 파일만 수정. 구현 파일은 `todo!()` 또는 stub 상태.
- 테스트는 반드시 컴파일되어야 함 (타입 오류 없이).
- `cargo test`가 실패 확인 후 다음 페이즈.

### Phase 2: Implementation (Green)

**AI에게:**
```
프롬프트 예시:
"위 테스트들을 통과시키는 최소한의 구현을 작성해줘.
- 테스트 파일은 수정하지 마.
- 과도한 최적화 금지. 테스트 통과가 목표.
- 모든 unwrap()에는 TODO 주석 필수."
```

**규칙:**
- 구현은 최소 경로로. "가장 단순하게 그린이 되는 코드".
- 이 단계에서 아키텍처 최적화 금지.
- `cargo test` 전체 그린 확인 후 다음 페이즈.

### Phase 3: Refactor

**AI에게:**
```
프롬프트 예시:
"현재 구현을 리팩터해줘.
- 테스트는 수정하지 마.
- 매 리팩터 단계 후 cargo test가 그린이어야 해.
- 리팩터할 항목: [구체적 지시]"
```

**규칙:**
- 리팩터 중에는 새 기능 추가 금지.
- 각 리팩터 단계가 독립적인 커밋이어야 함.
- `cargo clippy -- -D warnings` 리팩터 후 통과 필수.

---

## AI와 잘 맞는 추가 패러다임

### 1. Property-Based Testing (PBT) + AI

AI는 edge case 발견에 매우 뛰어나지만,
사람이 미처 생각 못 한 불변식(invariant)을 proptest로 검증하면
AI 구현의 숨겨진 버그를 더 잘 잡아.

```rust
// proptest로 불변식 기술 → AI에게 구현 위임
use proptest::prelude::*;

proptest! {
    #[test]
    fn email_round_trip(s in "[a-z]+@[a-z]+\\.[a-z]+") {
        let email = EmailAddress::parse(&s).unwrap();
        prop_assert_eq!(email.to_string(), s);
    }

    #[test]
    fn invalid_email_always_rejected(
        s in "[a-z]{1,20}"  // @ 없는 문자열
    ) {
        prop_assert!(EmailAddress::parse(&s).is_err());
    }
}
```

**AI 프롬프트 패턴:**
> "위 proptest 불변식을 모두 만족하는 EmailAddress 구현을 작성해줘.
> 반드시 proptest를 돌려서 확인해."

### 2. Contract-First Design + AI

타입 시그니처와 문서 주석(trait/struct)만 먼저 작성하고
구현을 AI에게 위임. Rust의 타입 시스템이 AI의 구현 범위를 자연스럽게 제한.

```rust
/// 사용자 저장소. 영속성 백엔드와 독립적으로 테스트 가능해야 한다.
#[async_trait]
pub trait UserRepository: Send + Sync {
    /// 존재하지 않으면 NotFound 에러.
    async fn find_by_id(&self, id: UserId) -> Result<User, RepositoryError>;
    
    /// 이메일 중복 시 AlreadyExists 에러.
    async fn create(&self, cmd: CreateUserCommand) -> Result<User, RepositoryError>;
    
    /// 없는 id이면 무시 (멱등성 보장).
    async fn delete(&self, id: UserId) -> Result<(), RepositoryError>;
}
```

**AI 프롬프트 패턴:**
> "위 trait의 in-memory 구현과 테스트를 작성해줘.
> trait 시그니처는 변경하지 마."

### 3. Mutation Testing + AI 리뷰

`cargo-mutants`로 뮤테이션 테스트 실행 후
AI에게 살아남은 뮤턴트(테스트가 잡지 못한 버그 후보) 분석 위임.

```bash
cargo mutants
# 살아남은 뮤턴트가 있으면 AI에게:
# "이 뮤턴트들이 테스트에서 잡히지 않은 이유와
#  이를 잡는 테스트를 추가해줘."
```

### 4. Acceptance TDD (ATDD) + Agent

비즈니스 레벨 acceptance test → 실패 → AI가 모든 레이어 구현.
가장 AI+TDD 시너지가 큰 패턴.

```rust
// acceptance test: HTTP 레벨에서 기술
#[tokio::test]
async fn user_can_register_and_login() {
    let app = spawn_test_app().await;
    
    // Register
    let response = app.post("/auth/register", json!({
        "email": "user@example.com",
        "password": "secure123"
    })).await;
    assert_eq!(response.status(), 201);
    
    // Login
    let response = app.post("/auth/login", json!({
        "email": "user@example.com",
        "password": "secure123"
    })).await;
    let token: String = response.json()["token"].as_str().unwrap().to_owned();
    assert!(!token.is_empty());
    
    // Access protected resource
    let response = app.get("/me").bearer(&token).await;
    assert_eq!(response.status(), 200);
}
```

**AI 프롬프트 패턴:**
> "위 acceptance test를 통과시키는 전체 구현을 작성해줘.
> Router, Handler, Service, Repository, Migration 모두 포함.
> 단계별로: 먼저 cargo test가 컴파일 오류 없이 실패하는지 확인 후
> 구현 시작."

---

## TDD 전용 Test Agent 설정

### 역할 분리

Agent Manager에서 테스트 전용 에이전트를 별도 운용:

| 에이전트 | 역할 | 파일 소유권 |
|---------|------|------------|
| **Test Agent** | 테스트 작성, 실패 확인, 뮤테이션 분석 | `tests/**`, `src/**/#[cfg(test)]` |
| **Impl Agent** | 테스트를 통과하는 구현 | `src/**` (테스트 블록 제외) |
| **Refactor Agent** | 그린 상태 유지하며 리팩터 | `src/**` |

**중요**: 각 에이전트는 자신의 파일 소유권 밖을 수정하지 않음.
Test Agent가 구현을 수정하거나, Impl Agent가 테스트를 수정하면 TDD 사이클 붕괴.

### Test Agent 운영 원칙

```
Test Agent의 유일한 성공 조건:
  cargo test → 새로 추가한 테스트가 실패 (RED)

Test Agent의 실패 조건:
  - 구현 파일 수정
  - 이미 통과하는 테스트 수정
  - 테스트가 컴파일조차 안 되는 상태로 종료
```

---

## 커밋 전략 (AI+TDD)

```
git commit -m "test: add failing tests for EmailAddress validation [RED]"
git commit -m "feat: implement EmailAddress to pass validation tests [GREEN]"
git commit -m "refactor: extract validation logic into validator module"
```

각 커밋 메시지에 `[RED]` / `[GREEN]` / `[REFACTOR]` 태그로
어느 TDD 페이즈인지 명확히 표시.
