---
name: openclaw-checkpoint
description: Create, tag, and push GitHub checkpoints for the OpenClaw workspace while excluding secrets; use this when the user wants a rollback-safe snapshot or restore point for the OpenClaw environment.
---

# OpenClaw Checkpoint

Use this skill when the user wants to checkpoint the OpenClaw environment, push changes to the GitHub checkpoint repo, or restore a prior state.

## Default workspace

- Work in `/Users/demo/.openclaw/workspace` unless the user says otherwise.
- Treat the repo as the source of truth for non-secret OpenClaw settings and memory notes.

## What to include

- `AGENTS.md`
- `BOOTSTRAP.md`
- `HEARTBEAT.md`
- `IDENTITY.md`
- `SOUL.md`
- `TOOLS.md`
- `USER.md`
- `.openclaw/workspace-state.json`
- Any other non-secret OpenClaw notes or config files the user explicitly wants preserved

## What to exclude

- API keys, tokens, secrets, and credentials
- `.env` and `.env.*`
- `auth-profiles.json`
- `device-auth.json`
- `credentials/`
- private keys and cert material

## Checkpoint workflow

1. Inspect the working tree for secret-like files before staging.
2. Run `scripts/openclaw-checkpoint.sh`.
3. Confirm the commit and tag names in the output.
4. Leave the repo clean after push.

## Restore workflow

- Prefer `scripts/openclaw-restore.sh <ref> <target-dir>` to inspect a prior checkpoint without disturbing the live workspace.
- Use a detached checkout only when the user explicitly wants the current repo moved to that checkpoint.
- Never overwrite unknown local changes without asking first.

## Operational notes

- Keep checkpoint commits small and timestamped.
- Push both the branch and the tag so the snapshot is easy to find later.
- If GitHub SSH auth fails, fix SSH before retrying the checkpoint.
