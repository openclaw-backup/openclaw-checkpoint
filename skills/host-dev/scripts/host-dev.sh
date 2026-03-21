#!/usr/bin/env bash
set -euo pipefail

RELAY_SH="/Users/demo/.openclaw/workspace/skills/tmux-agents-relay/scripts/relay.sh"

usage() {
  cat <<'EOF'
Usage: host-dev.sh <status|ensure|deliver|capture> [args...]

Commands:
  status            Check host relay readiness
  ensure            Create or reuse the host relay session
  deliver <prompt>  Send one host-development task to Claude Code and wait
  capture [target]  Read the latest output from the host relay
EOF
}

if [ ! -x "$RELAY_SH" ]; then
  echo "missing relay script: $RELAY_SH" >&2
  exit 2
fi

cmd="${1:-}"
shift || true

case "$cmd" in
  status|ensure|capture)
    exec "$RELAY_SH" "$cmd" "$@"
    ;;
  deliver)
    if [ "$#" -lt 1 ]; then
      echo "deliver requires a prompt" >&2
      exit 2
    fi

    prompt="$*"
    strict_prefix=$'HOST-DEV TASK (host Mac Claude Code only)\n- Do not solve locally.\n- Do not hand the task back to OpenClaw.\n- If the host relay cannot complete the task, report the failure explicitly.\n\n'
    exec "$RELAY_SH" deliver "${strict_prefix}${prompt}"
    ;;
  -h|--help|help|"")
    usage
    ;;
  *)
    echo "unknown command: $cmd" >&2
    usage >&2
    exit 2
    ;;
esac
