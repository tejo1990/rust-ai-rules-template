---
name: rust-web-axum
description: |
  Activate when working on a Rust web backend using Axum, SQLx, or Tokio.
  Provides project conventions, layer architecture, and Rust-specific
  patterns for building production-grade async web APIs.
triggers:
  - axum
  - sqlx
  - tower
  - tokio
  - async web
  - REST API in Rust
  - handler
  - repository
  - migration
---

# Skill: Rust Web Backend (Axum + SQLx)

## When This Skill Is Active
You are working on a Rust async web API. The stack is:
- **Axum** for routing and HTTP handling
- **SQLx** with PostgreSQL for database access
- **Tokio** as the async runtime
- **Tower** for middleware

## Layer Architecture (strict)
```
Router → Handler → Service → Repository → DB
```
- **Handler**: extract request, validate DTO, call service, return response.
  No business logic here.
- **Service**: owns business rules. Testable without HTTP.
- **Repository**: trait-based DB abstraction. `Arc<dyn Repo>` in service.
- **Error**: `src/error.rs` — single `Error` enum with `thiserror`,
  implements `IntoResponse` with explicit HTTP code mapping.

## Agent Task Split
When spawning sub-agents for a feature:
| Agent | File Scope |
|-------|------------|
| A — Schema | `migrations/`, `src/db/` |
| B — Service | `src/service/` |
| C — API | `src/api/` (handlers + router) |

Agents must not write outside their declared scope.
After each agent completes: run `cargo check && cargo test` before continuing.

## Key Patterns

### Error type skeleton
```rust
// src/error.rs
#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("not found")]
    NotFound,
    #[error("unauthorized")]
    Unauthorized,
    #[error("database error: {0}")]
    Database(#[from] sqlx::Error),
}

impl axum::response::IntoResponse for Error {
    fn into_response(self) -> axum::response::Response {
        let (status, code) = match &self {
            Error::NotFound     => (StatusCode::NOT_FOUND,            "NOT_FOUND"),
            Error::Unauthorized => (StatusCode::UNAUTHORIZED,         "UNAUTHORIZED"),
            Error::Database(_)  => (StatusCode::INTERNAL_SERVER_ERROR, "DB_ERROR"),
        };
        let body = serde_json::json!({ "error": { "code": code, "message": self.to_string() } });
        (status, axum::Json(body)).into_response()
    }
}
```

### Repository trait pattern
```rust
#[async_trait]
pub trait UserRepo: Send + Sync {
    async fn find_by_id(&self, id: Uuid) -> Result<User, Error>;
    async fn create(&self, dto: CreateUserDto) -> Result<User, Error>;
}

pub struct PgUserRepo { pool: PgPool }

#[async_trait]
impl UserRepo for PgUserRepo {
    async fn find_by_id(&self, id: Uuid) -> Result<User, Error> {
        sqlx::query_as!(User, "SELECT * FROM users WHERE id = $1", id)
            .fetch_optional(&self.pool)
            .await?
            .ok_or(Error::NotFound)
    }
    // ...
}
```

### Thin handler
```rust
async fn get_user(
    State(svc): State<Arc<dyn UserService>>,
    Path(id): Path<Uuid>,
) -> Result<Json<UserDto>, Error> {
    let user = svc.get_user(id).await?;
    Ok(Json(UserDto::from(user)))
}
```

## Verification Checklist
- [ ] `cargo check` passes
- [ ] `cargo clippy -- -D warnings` passes
- [ ] `cargo test` passes (including `sqlx::test` repo tests)
- [ ] `sqlx migrate run` succeeds
- [ ] No DB models exposed directly in API responses
