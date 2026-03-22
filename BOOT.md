# BOOT.md

- For any request that mentions "host development environment", "Claude Code", "host-dev", "host Mac", or "remote Mac development", immediately route to the `host-dev` skill and its relay wrapper.
- Do not satisfy those requests with local OpenClaw code generation, `exec`, or direct `ssh`.
- If the request is underspecified, ask the minimum necessary question, then continue with `host-dev`.
- For host-development tasks, return only a completion-shaped result or an explicit blocker.
