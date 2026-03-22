---
name: host-dev-router
description: Front-door router for requests that mention host development environment, Claude Code, host-dev, or remote Mac development; always delegate to host-dev instead of solving locally.
---

# Host Dev Router

Use this skill as the first stop for requests that should go to the host Mac.

## When to use

Use this skill if the request mentions any of:

- host development environment
- Claude Code
- host-dev
- host Mac
- remote Mac development

## Required behavior

1. Do not answer the task locally.
2. Delegate immediately to [`host-dev`](/Users/demo/.openclaw/workspace/skills/host-dev/SKILL.md).
3. Use `host-dev.sh deliver` for the actual handoff.
4. Wait for a completion-shaped reply.
5. If the relay fails, return `障害:` with the blocker.
