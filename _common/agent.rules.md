# Agentic Workflow Rules (standalone reference)

Same content as the `## Agentic Workflow` section in `base.rules.md`.
This file exists for platforms or tools that load rules files separately.

## Planning Before Acting
- Before writing any code, produce an explicit **Implementation Plan**:
  list files to create/modify, modules to add, and the order of operations.
- Break tasks larger than ~200 lines of change into sequential sub-tasks.
  Complete and verify each sub-task before starting the next.
- If a task is ambiguous, output a **clarification list** and pause.
  Do not make silent assumptions on architecture-level decisions.

## Sub-agent / Parallel Task Delegation
- When the platform supports sub-agents or parallel tasks,
  split work along clear module or crate boundaries:
    - One agent per crate in a workspace.
    - One agent for schema/migrations, one for business logic,
      one for API handlers — never overlap file ownership.
- Each delegated sub-task must include:
    1. A precise file scope (which files it may read/write).
    2. Its input contract (types, traits it receives).
    3. Its output contract (types, traits it must produce).
- Sub-agents must not modify files outside their declared scope.
  Escalate scope conflicts to the orchestrator rather than silently overwriting.

## Verification After Each Step
- After every non-trivial change, run:
    cargo check
    cargo clippy -- -D warnings
    cargo test
- Do not proceed to the next sub-task if any of the above fail.

## Tool & Terminal Use
- Prefer `cargo` subcommands over manual file manipulation.
- Limit terminal commands to the project directory.
- Show all shell commands to the user before execution
  unless in "Always Proceed" mode for read-only commands.

## Context & Memory Management
- Re-read project rules at the start of each agent session.
- Maintain `AGENT_LOG.md` at the project root:
    - Completed sub-tasks with outcomes.
    - Decisions made and rationale.
    - Open questions or blockers.
- Summarize completed work into `AGENT_LOG.md` when context pressure is high.

## Scope Discipline
- Never refactor outside current task scope. Log improvements in `AGENT_LOG.md`.
- Do not add unasked-for dependencies without proposing and waiting for approval.
- Feature creep from the agent side is a bug, not a feature.
