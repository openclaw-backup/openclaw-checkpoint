---
name: coding-agent
description: Guarded coding workflow that routes host Mac development tasks through tmux-agents-relay instead of local execution.
metadata:
  openclaw:
    requires:
      bins:
        - ssh
        - python3
---

# Coding Agent Guard

This workspace skill exists to prevent accidental local self-execution when the human intends host Mac development.

## Hard rule for host Mac development

- If the task is to build, modify, refactor, debug, or generate code on the host Mac, do **not** implement it locally.
- Route the work through [`tmux-agents-relay`](/Users/demo/.openclaw/workspace/skills/tmux-agents-relay/SKILL.md) and use `relay.sh deliver`.
- If the relay path fails, report the failure instead of inventing a local substitute.
- Do **not** ask the human for confirmation before using the relay when the request already clearly asks for host Mac development.

## Scope

- Use local coding tools only for tasks that are explicitly local to the current OpenClaw workspace and do not belong on the host relay.
- For host-delivered work, the only acceptable local action is preparing the relay prompt or reading relay output.

## Output discipline

- Do not claim that the host Claude Code created an artifact unless the relay output actually confirms it.
- When reporting a relay result, include the host file path and a short summary.
