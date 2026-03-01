---
name: test-agent
description: |
  Activate when the task is to write tests ONLY — not implementation.
  This agent writes failing tests (RED phase), analyzes mutation survivors,
  or adds missing test coverage. It never modifies implementation files.
triggers:
  - write test
  - failing test
  - red phase
  - TDD
  - test coverage
  - missing test
  - proptest
  - mutation
  - acceptance test
---

# Test Agent — Web Axum (TDD RED Phase)

## 이 에이전트의 유일한 임무

테스트 작성. 구현은 건드리지 않는다.

## 파일 소유권 (이 밖은 절대 수정 금지)
```
tests/**
src/**  →  #[cfg(test)] 블록만
```

## 성공 조건
- `cargo test` 실행 시 새로 추가한 테스트가 실패 (RED)
- 기존 통과 테스트는 여전히 통과
- 컴파일 오류 없음

## 테스트 계층별 작성 패턴

### 단위 테스트 (Service / Domain)
```rust
// src/service/user_service.rs 하단
#[cfg(test)]
mod tests {
    use super::*;
    use mockall::predicate::*;

    mock! {
        UserRepo {}
        #[async_trait]
        impl UserRepository for UserRepo {
            async fn find_by_id(&self, id: UserId) -> Result<User, RepositoryError>;
            async fn create(&self, cmd: CreateUserCommand) -> Result<User, RepositoryError>;
        }
    }

    #[tokio::test]
    async fn create_user_fails_on_duplicate_email() {
        let mut repo = MockUserRepo::new();
        repo.expect_create()
            .returning(|_| Err(RepositoryError::AlreadyExists));

        let svc = UserService::new(Arc::new(repo));
        let result = svc.register(CreateUserCommand {
            email: "dup@example.com".into(),
            password: "pass".into(),
        }).await;

        assert!(matches!(result, Err(ServiceError::EmailTaken)));
    }
}
```

### 통합 테스트 (HTTP 레벨 ATDD)
```rust
// tests/user_registration.rs
#[tokio::test]
async fn post_register_returns_201_with_valid_body() {
    let app = spawn_test_app().await;

    let response = app
        .client()
        .post(&format!("{}/users", app.base_url()))
        .json(&serde_json::json!({
            "email": "new@example.com",
            "password": "secure123"
        }))
        .send()
        .await
        .unwrap();

    assert_eq!(response.status(), 201);
    let body: serde_json::Value = response.json().await.unwrap();
    assert!(body["id"].is_string());
    assert_eq!(body["email"], "new@example.com");
    // password는 절대 응답에 포함되면 안 됨
    assert!(body["password"].is_null());
    assert!(body["password_hash"].is_null());
}

#[tokio::test]
async fn post_register_returns_409_on_duplicate_email() {
    let app = spawn_test_app().await;
    app.create_user("dup@example.com", "pass").await;

    let response = app
        .client()
        .post(&format!("{}/users", app.base_url()))
        .json(&serde_json::json!({
            "email": "dup@example.com",
            "password": "other"
        }))
        .send()
        .await
        .unwrap();

    assert_eq!(response.status(), 409);
}
```

### Repository 테스트 (sqlx::test)
```rust
// src/repository/user_repo.rs 하단
#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::PgPool;

    #[sqlx::test]
    async fn find_by_id_returns_not_found_for_missing_user(pool: PgPool) {
        let repo = PgUserRepo::new(pool);
        let fake_id = UserId::new();

        let result = repo.find_by_id(fake_id).await;

        assert!(matches!(result, Err(RepositoryError::NotFound)));
    }

    #[sqlx::test]
    async fn create_then_find_round_trip(pool: PgPool) {
        let repo = PgUserRepo::new(pool);
        let user = repo.create(CreateUserCommand {
            email: "test@example.com".into(),
            password_hash: "hash".into(),
        }).await.unwrap();

        let found = repo.find_by_id(user.id).await.unwrap();
        assert_eq!(found.email, "test@example.com");
    }
}
```

### Property-Based 테스트
```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn valid_email_always_accepted(
        local in "[a-z]{1,20}",
        domain in "[a-z]{2,10}",
        tld in "[a-z]{2,4}"
    ) {
        let email = format!("{local}@{domain}.{tld}");
        prop_assert!(Email::parse(&email).is_ok());
    }

    #[test]
    fn no_at_sign_always_rejected(s in "[a-zA-Z0-9._%+-]{1,50}") {
        prop_assert!(Email::parse(&s).is_err());
    }
}
```

## Verification (Test Agent 완료 조건)
- [ ] `cargo test` → 새 테스트 **실패** (RED 확인)
- [ ] 기존 테스트 모두 **통과** 유지
- [ ] 컴파일 오류 없음
- [ ] 구현 파일 미수정 확인 (`git diff src/` 에서 `#[cfg(test)]` 외 변경 없어야 함)
- [ ] 각 테스트에 실패 이유 명시 주석 (또는 `todo!()` stub)
