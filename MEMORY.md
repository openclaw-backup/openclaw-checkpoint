# Memory

## Current Runtime State

- OpenClaw gateway runs on `ws://127.0.0.1:18789`
- Gateway is supervised by `launchd` and wrapped in `tmux`
- Dedicated browser profile: `openclaw`
- Control UI and browser automation are active

## Secret Handling

- Gateway auth token is stored in macOS Keychain under `openclaw-gateway` / `openclaw-gateway-token`
- Discord bot token is stored in macOS Keychain under `openclaw-discord` / `openclaw-discord-bot-token`
- Secrets are excluded from Git checkpoints

## Discord Configuration

- Server ID: `1469506738108498134`
- Channel ID: `1469506739509526530`
- User ID allowlist: `980872621627441202`
- App ID: `1469357975608230131`
- Discord channel mode is enabled
- Guild channel replies require mentions
- Direct messages are allowlisted to the owner user

## GitHub Checkpoint Repo

- Repository: `openclaw-backup/openclaw-checkpoint`
- Auth: SSH key
- Checkpoints are created with the `openclaw-checkpoint` workflow

## Host Mac Relay

- Host alias: `AbenoiMac`
- Host user: `yurika`
- Host workdir: `/Users/yurika/dev`
- SSH key for relay: `~/.ssh/openclaw-tmux-agents`
- Host relay skill: `tmux-agents-relay`
- Current blocker on host: `tmux` and `claude` were missing before bootstrap
- Preferred relay flow: use `relay.sh deliver <prompt>` for development tasks that should run on host Claude Code
- Delegation rule: do not satisfy host-code requests locally when the relay path is available; capture and summarize the host result instead
