#!/usr/bin/env bash
set -euo pipefail

HOST_ALIAS="${OPENCLAW_HOST_RELAY_HOST:-openclaw-relay-host}"
HOST_USER="${OPENCLAW_HOST_RELAY_USER:-yurika}"
HOST_WORKDIR="${OPENCLAW_HOST_RELAY_WORKDIR:-/Users/yurika/dev}"
HOST_SESSION="${OPENCLAW_HOST_RELAY_SESSION:-openclaw-relay}"
HOST_WORKER_WINDOW="${OPENCLAW_HOST_RELAY_WORKER_WINDOW:-worker}"
HOST_MONITOR_LOG="${OPENCLAW_HOST_RELAY_LOG:-/tmp/openclaw-host-relay.log}"
SSH_KEY="${OPENCLAW_HOST_RELAY_KEY:-/Users/demo/.ssh/openclaw-tmux-agents}"
HOST_TMUX_BIN="${OPENCLAW_HOST_RELAY_TMUX_BIN:-/opt/homebrew/bin/tmux}"
HOST_CLAUDE_BIN="${OPENCLAW_HOST_RELAY_CLAUDE_BIN:-/Users/yurika/.local/bin/claude}"

usage() {
  cat <<'EOF'
Usage: relay.sh <status|ensure|task|deliver|capture|attach|stop> [args...]

Commands:
  status                 Check host SSH, tmux, claude, and relay session status
  ensure                 Create or reuse the host tmux relay session
  task <prompt>           Send one Claude Code task to the host relay session
  deliver <prompt>        Ensure relay, send a task, and wait for captured output
  capture [target]        Capture output from the host worker window or session
  attach                  SSH to the host and attach to the relay session
  stop                    Kill the host relay session
EOF
}

quote_shell() {
  python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

ssh_host() {
  env -i HOME="${HOME:-/Users/demo}" USER="$HOST_USER" PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
    /usr/bin/ssh -i "$SSH_KEY" \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=accept-new \
    "${HOST_USER}@${HOST_ALIAS}" "$@"
}

remote_env_prefix() {
  printf 'HOST_SESSION=%s HOST_WORKER_WINDOW=%s HOST_WORKDIR=%s HOST_MONITOR_LOG=%s HOST_TMUX_BIN=%s HOST_CLAUDE_BIN=%s ' \
    "$(quote_shell "$HOST_SESSION")" \
    "$(quote_shell "$HOST_WORKER_WINDOW")" \
    "$(quote_shell "$HOST_WORKDIR")" \
    "$(quote_shell "$HOST_MONITOR_LOG")" \
    "$(quote_shell "$HOST_TMUX_BIN")" \
    "$(quote_shell "$HOST_CLAUDE_BIN")"
}

cmd_status() {
  ssh_host "$(remote_env_prefix) bash -se" <<'REMOTE'
set -euo pipefail

echo "host: $(hostname)"
echo "user: $(whoami)"

if [ -x "$HOST_TMUX_BIN" ]; then
  echo "tmux: $("$HOST_TMUX_BIN" -V)"
else
  echo "tmux: missing"
fi

if [ -x "$HOST_CLAUDE_BIN" ]; then
  echo "claude: present"
  "$HOST_CLAUDE_BIN" --version || true
else
  echo "claude: missing"
fi

if "$HOST_TMUX_BIN" has-session -t "$HOST_SESSION" 2>/dev/null; then
  echo "session: $HOST_SESSION present"
  "$HOST_TMUX_BIN" list-panes -t "$HOST_SESSION" -F '#{session_name}:#{window_index}.#{pane_index} #{pane_current_command} #{pane_title}' || true
else
  echo "session: $HOST_SESSION missing"
fi
REMOTE
}

cmd_ensure() {
  ssh_host "$(remote_env_prefix) bash -se" <<'REMOTE'
set -euo pipefail

: "${HOST_SESSION:?}"
: "${HOST_WORKER_WINDOW:?}"
: "${HOST_WORKDIR:?}"
: "${HOST_MONITOR_LOG:?}"
: "${HOST_TMUX_BIN:?}"
: "${HOST_CLAUDE_BIN:?}"

if [ ! -x "$HOST_TMUX_BIN" ]; then
  echo "host prerequisite missing: tmux"
  echo "Install on the host Mac, then rerun:"
  echo "  brew install tmux"
  exit 2
fi

if [ ! -x "$HOST_CLAUDE_BIN" ]; then
  echo "host prerequisite missing: claude"
  echo "Install on the host Mac, then rerun:"
  echo "  curl -fsSL https://claude.ai/install.sh | bash"
  exit 2
fi

if ! "$HOST_TMUX_BIN" has-session -t "$HOST_SESSION" 2>/dev/null; then
  "$HOST_TMUX_BIN" new-session -d -s "$HOST_SESSION" -n "$HOST_WORKER_WINDOW" -c "$HOST_WORKDIR" "exec /bin/zsh -l"
  "$HOST_TMUX_BIN" split-window -v -t "$HOST_SESSION:$HOST_WORKER_WINDOW" -c "$HOST_WORKDIR" "tail -n 100 -f '$HOST_MONITOR_LOG'"
  "$HOST_TMUX_BIN" select-pane -t "$HOST_SESSION:$HOST_WORKER_WINDOW.0"
fi

"$HOST_TMUX_BIN" set-option -t "$HOST_SESSION" remain-on-exit on >/dev/null 2>&1 || true
echo "ready: $HOST_SESSION"
REMOTE
}

cmd_task() {
  if [ "$#" -lt 1 ]; then
    echo "task requires a prompt" >&2
    exit 2
  fi

  local prompt="$*"
  local prompt_quoted window_name marker marker_quoted
  prompt_quoted="$(quote_shell "$prompt")"
  window_name="task-$(date +%Y%m%d-%H%M%S)"
  marker="__OPENCLAW_RELAY_DONE__:${window_name}"
  marker_quoted="$(quote_shell "$marker")"

  ssh_host "PROMPT=$prompt_quoted WINDOW=$(quote_shell "$window_name") MARKER=$marker_quoted $(remote_env_prefix) bash -se" <<'REMOTE'
set -euo pipefail

: "${HOST_SESSION:?}"
: "${HOST_WORKER_WINDOW:?}"
: "${HOST_WORKDIR:?}"
: "${HOST_MONITOR_LOG:?}"
: "${PROMPT:?}"
: "${WINDOW:?}"
: "${MARKER:?}"
: "${HOST_TMUX_BIN:?}"
: "${HOST_CLAUDE_BIN:?}"

if [ ! -x "$HOST_TMUX_BIN" ] || [ ! -x "$HOST_CLAUDE_BIN" ]; then
  echo "host relay prerequisites missing" >&2
  exit 2
fi

if ! "$HOST_TMUX_BIN" has-session -t "$HOST_SESSION" 2>/dev/null; then
  echo "host relay session missing; run ensure first" >&2
  exit 2
fi

prompt_q=$(python3 - "$PROMPT" <<'PY'
import shlex
import sys
print(shlex.quote(sys.argv[1]))
PY
)
log_q=$(python3 - "$HOST_MONITOR_LOG" <<'PY'
import shlex
import sys
print(shlex.quote(sys.argv[1]))
PY
)
workdir_q=$(python3 - "$HOST_WORKDIR" <<'PY'
import shlex
import sys
print(shlex.quote(sys.argv[1]))
PY
)
marker_q=$(python3 - "$MARKER" <<'PY'
import shlex
import sys
print(shlex.quote(sys.argv[1]))
PY
)

task_script=$(mktemp /tmp/openclaw-relay-task.XXXXXX)
cat > "$task_script" <<EOF
#!/usr/bin/env bash
set -u
cd $workdir_q
status=0
{
  env PATH=/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin \
    printf '%s\n' $prompt_q | \
    env PATH=/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin \
    $HOST_CLAUDE_BIN --permission-mode bypassPermissions --print --add-dir $workdir_q 2>&1 | tee -a $log_q
} || status=\$?
printf '%s\n' $marker_q
printf '%s\n' "__OPENCLAW_RELAY_STATUS__:\$status"
exit \$status
EOF
chmod +x "$task_script"

"$HOST_TMUX_BIN" new-window -t "$HOST_SESSION" -n "$WINDOW" -c "$HOST_WORKDIR"
"$HOST_TMUX_BIN" send-keys -t "$HOST_SESSION:$WINDOW" "bash $task_script" Enter
"$HOST_TMUX_BIN" select-window -t "$HOST_SESSION:$WINDOW"
echo "$WINDOW"
REMOTE
}

cmd_deliver() {
  if [ "$#" -lt 1 ]; then
    echo "deliver requires a prompt" >&2
    exit 2
  fi

  cmd_ensure
  local window_name
  window_name="$(cmd_task "$@")"

  ssh_host "WINDOW=$(quote_shell "$window_name") $(remote_env_prefix) bash -se" <<'REMOTE'
set -euo pipefail

: "${HOST_SESSION:?}"
: "${WINDOW:?}"
: "${HOST_TMUX_BIN:?}"

marker="__OPENCLAW_RELAY_DONE__:${WINDOW}"
target="$HOST_SESSION:$WINDOW"

for _ in $(seq 1 180); do
  if "$HOST_TMUX_BIN" has-session -t "$HOST_SESSION" 2>/dev/null; then
    if output=$("$HOST_TMUX_BIN" capture-pane -pt "$target" -S -200 2>/dev/null); then
      if printf '%s\n' "$output" | grep -Fq "$marker"; then
        relay_status=$(printf '%s\n' "$output" | sed -n 's/^__OPENCLAW_RELAY_STATUS__://p' | tail -n 1)
        printf '%s\n' "$output" | grep -Fvx "$marker" | grep -Ev '^__OPENCLAW_RELAY_STATUS__:[0-9]+$'
        if [ -n "${relay_status:-}" ] && [ "$relay_status" != "0" ]; then
          echo "relay task exited with status $relay_status" >&2
          exit "$relay_status"
        fi
        exit 0
      fi
    fi
  fi
  sleep 1
done

echo "timeout waiting for relay completion: $target" >&2
"$HOST_TMUX_BIN" capture-pane -pt "$target" -S -200
exit 3
REMOTE
}

cmd_capture() {
  local target="${1:-$HOST_SESSION:$HOST_WORKER_WINDOW}"
  ssh_host "TARGET=$(quote_shell "$target") $(remote_env_prefix) bash -se" <<'REMOTE'
set -euo pipefail

: "${TARGET:?}"
: "${HOST_TMUX_BIN:?}"

session="${TARGET%%:*}"
if [ ! -x "$HOST_TMUX_BIN" ]; then
  echo "host prerequisite missing: tmux" >&2
  exit 2
fi

if "$HOST_TMUX_BIN" has-session -t "$session" 2>/dev/null; then
  "$HOST_TMUX_BIN" capture-pane -pt "$TARGET" -S -200
else
  echo "missing target: $TARGET" >&2
  exit 2
fi
REMOTE
}

cmd_attach() {
ssh -i "$SSH_KEY" \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=accept-new \
    -t "${HOST_USER}@${HOST_ALIAS}" "$HOST_TMUX_BIN attach -t '$HOST_SESSION'"
}

cmd_stop() {
  ssh_host "$(remote_env_prefix) bash -se" <<'REMOTE'
set -euo pipefail

if [ -x "$HOST_TMUX_BIN" ] && "$HOST_TMUX_BIN" has-session -t "$HOST_SESSION" 2>/dev/null; then
  "$HOST_TMUX_BIN" kill-session -t "$HOST_SESSION"
  echo "stopped: $HOST_SESSION"
else
  echo "stopped: $HOST_SESSION (already absent)"
fi
REMOTE
}

main() {
  local cmd="${1:-}"
  shift || true

  case "$cmd" in
    status) cmd_status "$@" ;;
    ensure) cmd_ensure "$@" ;;
    task) cmd_task "$@" ;;
    deliver) cmd_deliver "$@" ;;
    capture) cmd_capture "$@" ;;
    attach) cmd_attach "$@" ;;
    stop) cmd_stop "$@" ;;
    ""|-h|--help|help) usage ;;
    *)
      echo "unknown command: $cmd" >&2
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
