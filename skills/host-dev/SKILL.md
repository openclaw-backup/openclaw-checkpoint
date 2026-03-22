---
name: host-dev
description: Route host Mac development tasks, especially when the user says host development environment, Claude Code, host-dev, or remote Mac development, to the host Claude Code over tmux-agents-relay instead of solving them locally.
---

# Host Dev

Use this skill when the task should be executed on the host Mac by Claude Code.

## Trigger phrases

- "host development environment"
- "Claude Code"
- "host-dev"
- "host Mac"
- "remote Mac development"

When any of those phrases appear in the request, do not keep the task local. Route immediately to the host relay.

## Hard rule

- Do not satisfy host-development requests with local OpenClaw code generation, `exec`, direct `ssh`, or other local fallbacks.
- Always route host-development work through [`tmux-agents-relay`](/Users/demo/.openclaw/workspace/skills/tmux-agents-relay/SKILL.md).
- If the relay path fails, report the failure instead of inventing a local substitute.

## Canonical entrypoint

Use `scripts/host-dev.sh` as the normal relay wrapper.

## Workflow

1. Confirm relay readiness with `host-dev.sh status`.
2. Send one narrow task with `host-dev.sh deliver "<task>"`.
3. Do not ask the human for extra confirmation unless the task is genuinely underspecified.
4. Require the host result to include the changed path(s) and a short summary.
5. Use `capture` only when you need live output or failure inspection.

## Prompt shape

Make the host task explicit about:

- the target path on the host Mac
- the desired artifact or code change
- the output format: report only file path + short summary

Example:

```text
Create /Users/yurika/dev/demo/index.html on the host Mac.
Do not edit locally.
Report only the final file path and a short summary.
```

## Scope

- Use this skill for host Mac build, modify, refactor, debug, and generate tasks.
- Use local tools only for reading relay output or preparing the relay prompt.

## Completion contract

- Treat progress-only replies as failures.
- Return only one of:
  - `完了: <absolute path> + 1 line summary`
  - `障害: <specific blocker>`
- If the relay output is missing a completion shape, keep waiting for the relay marker and do not synthesize a local answer.
