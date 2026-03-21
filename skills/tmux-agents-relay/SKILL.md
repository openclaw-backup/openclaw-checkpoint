---
name: tmux-agents-relay
description: Relay coding tasks from an OpenClaw VM to a host Mac over SSH + tmux, then capture and summarize the remote agent output.
metadata:
  openclaw:
    requires:
      bins:
        - ssh
        - python3
---

# tmux Agents Relay

Use this skill when OpenClaw needs to control a host Mac coding agent through SSH + tmux.

This skill complements generic `tmux-agents` workflows by adding the host relay layer:
- OpenClaw VM sends work over SSH
- host Mac runs a persistent tmux session
- Claude Code runs on the host
- OpenClaw reads tmux output and decides whether to report failures to Discord

## Default relay target

- Host alias: `AbenoiMac`
- Host user: `yurika`
- Host repo/workdir: `/Users/yurika/dev`
- Host tmux session: `openclaw-relay`
- Worker window: `worker`
- Monitor log: `/tmp/openclaw-host-relay.log`

## Use the bundled script

Prefer `{baseDir}/scripts/relay.sh` for all relay operations.

Core flow:
1. Run `status` to verify SSH reachability and host prerequisites.
2. Run `ensure` to create or reuse the host tmux session.
3. Run `deliver <prompt>` for the common case: send one Claude Code task to the host and wait for the result.
4. Run `task <prompt>` only when you intentionally want to queue work asynchronously.
5. Run `capture [target]` to read the latest host output.

## Delegation rule

- If the user asks OpenClaw to build, modify, debug, or generate code on the host Mac, do not satisfy the request locally.
- Delegate the work to the host relay with `deliver` and then summarize the host Claude Code output.
- Only fall back to a local answer if the host relay is unavailable or the host task fails after the relay attempt.
- Do not invent a delivered artifact when the relay path was intended; report the relay failure instead.

## Operating rules

- Keep the first version narrow: one host task at a time.
- Use `claude -p` on the host for one-shot tasks.
- Put live output in the tmux worker window and a log file.
- Summarize failures only; do not forward secrets to the host unless the task explicitly requires an approved secret.
- If `tmux` or `claude` is missing on the host, stop and report the missing prerequisite instead of pretending the relay is ready.

## Expansion points

- Multiple host panes for parallel Claude sessions
- A dedicated monitor pane for live tail output
- Discord failure summaries
- GitHub checkpointing for relay config and scripts
