---
name: rust-embedded
description: |
  Activate when working on Rust firmware using Embassy, RTIC, or bare-metal no_std.
  Provides memory-safe patterns, peripheral init conventions, and
  Embassy async task architecture for embedded targets.
triggers:
  - embassy
  - rtic
  - no_std
  - embedded-hal
  - defmt
  - cortex-m
  - nrf
  - stm32
  - rp2040
  - firmware
  - peripheral
  - DMA
  - interrupt
---

# Skill: Rust Embedded Firmware (Embassy / RTIC)

## When This Skill Is Active
You are writing Rust firmware for a microcontroller.
Target is no_std. Embassy or RTIC is the concurrency framework.

## Critical Constraints
- No heap. All allocations are static or stack-based.
- No `println!`. Use `defmt::info!`, `defmt::warn!`, `defmt::error!`.
- No `unwrap()` on peripheral init without a reset/halt recovery path.
- Binary size budget: run `cargo size` before and after every feature.

## Agent Task Split
For a new peripheral or feature:
| Agent | File Scope |
|-------|------------|
| A — Driver | `src/drivers/` |
| B — Tasks  | `src/tasks/`   |
| C — Config | `src/config/`, `memory.x`, `.cargo/config.toml` |

After each agent: `cargo check --target <target>` + `cargo size` must pass.

## Key Patterns

### Embassy Task (owns its peripheral)
```rust
#[embassy_executor::task]
async fn uart_task(mut uart: UarteWithIdle<'static, UARTE0>) {
    let mut buf = [0u8; 256];  // stack allocated, bounded
    loop {
        match embassy_time::with_timeout(
            Duration::from_millis(1000),
            uart.read_until_idle(&mut buf),
        ).await {
            Ok(Ok(n))  => handle_data(&buf[..n]),
            Ok(Err(e)) => defmt::error!("uart error: {:?}", e),
            Err(_)     => defmt::warn!("uart timeout"),
        }
    }
}
```

### Inter-task communication (Embassy)
```rust
// In shared module
static CHANNEL: Channel<CriticalSectionRawMutex, SensorData, 4> = Channel::new();

// Sender task
CHANNEL.send(data).await;

// Receiver task
let data = CHANNEL.receive().await;
```

### Shared state (Embassy Mutex)
```rust
static CONFIG: Mutex<CriticalSectionRawMutex, Option<Config>> = Mutex::new(None);

// Write
CONFIG.lock(|c| *c = Some(new_config));

// Read
CONFIG.lock(|c| c.as_ref().map(|cfg| cfg.value));
```

### No-std Error type
```rust
#[derive(Debug, defmt::Format)]
pub enum AppError {
    Spi(SpiError),
    Timeout,
    InvalidData,
}

impl From<SpiError> for AppError {
    fn from(e: SpiError) -> Self { AppError::Spi(e) }
}
```

## Verification Checklist
- [ ] `cargo check --target <target>` passes
- [ ] `cargo clippy --target <target> -- -D warnings` passes
- [ ] `cargo size` — binary within budget
- [ ] No `static mut` without critical section
- [ ] No blocking in async tasks
- [ ] Panic handler defined
- [ ] `memory.x` matches chip datasheet
