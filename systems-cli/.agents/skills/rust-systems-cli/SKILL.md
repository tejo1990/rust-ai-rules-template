---
name: rust-systems-cli
description: |
  Activate when working on a Rust CLI tool, system daemon, or performance-sensitive
  systems program. Provides clap patterns, concurrency conventions,
  graceful shutdown, and testing patterns for production Rust binaries.
triggers:
  - clap
  - CLI
  - daemon
  - signal
  - SIGTERM
  - tracing
  - rayon
  - crossbeam
  - memmap
  - indicatif
  - systems programming
  - binary
  - graceful shutdown
---

# Skill: Rust Systems / CLI / Daemon

## When This Skill Is Active
You are building a Rust binary: a CLI tool, long-running daemon,
or performance-sensitive systems program.

## Agent Task Split
| Agent | File Scope |
|-------|------------|
| A — CLI    | `src/cli/` (args, subcommands, output formatting) |
| B — Core   | `src/core/` (domain logic, pure functions)       |
| C — I/O    | `src/io/`, `src/daemon/` (signals, config, files) |

After each agent: `cargo check && cargo clippy -- -D warnings && cargo test`.

## Key Patterns

### CLI structure (clap derive)
```rust
#[derive(Parser)]
#[command(author, version, about)]
struct AppArgs {
    #[command(subcommand)]
    command: Commands,
    #[arg(long, global = true)]
    json: bool,
}

#[derive(Subcommand)]
enum Commands {
    /// Run the main operation
    Run(RunArgs),
    /// Show current config
    Config,
}
```

### Exit codes
```rust
fn main() {
    if let Err(e) = run() {
        match e {
            AppError::UserInput(_) => {
                eprintln!("error: {e}");
                std::process::exit(1);
            }
            _ => {
                eprintln!("internal error: {e}");
                std::process::exit(2);
            }
        }
    }
}
```

### Graceful shutdown
```rust
async fn run_daemon() -> Result<(), AppError> {
    let (shutdown_tx, shutdown_rx) = tokio::sync::broadcast::channel(1);

    // Spawn workers
    let worker = tokio::spawn(worker_loop(shutdown_rx));

    // Wait for signal
    tokio::signal::ctrl_c().await?;
    tracing::info!("shutdown signal received, draining...");
    let _ = shutdown_tx.send(());

    // Wait for clean exit
    worker.await??;
    tracing::info!("shutdown complete");
    Ok(())
}
```

### Structured logging
```rust
// main.rs init
let fmt = tracing_subscriber::fmt()
    .with_env_filter(EnvFilter::from_default_env());

if args.json {
    fmt.json().init();
} else {
    fmt.pretty().init();
}

// Usage
tracing::info!(user_id = %id, action = "login", "user authenticated");
tracing::error!(err = ?e, "database connection failed");
```

### CLI integration test (assert_cmd)
```rust
#[test]
fn test_run_outputs_json() {
    let mut cmd = Command::cargo_bin("my-tool").unwrap();
    cmd.args(["run", "--json"])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"status\""));
}
```

## Verification Checklist
- [ ] `cargo check` passes
- [ ] `cargo clippy -- -D warnings` passes
- [ ] `cargo test` passes (unit + integration)
- [ ] `--help` output matches intended CLI contract
- [ ] `--json` flag produces valid JSON on stdout
- [ ] SIGTERM causes graceful shutdown (tested manually or via assert_cmd)
- [ ] Errors go to stderr; normal output to stdout
