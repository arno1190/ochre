#!/usr/bin/env bash
# Ralph loop for Ochre: run build iterations until progress.txt says COMPLETED or BLOCKED.
# Usage: MAX_ITERATIONS=20 CLAUDE_FLAGS="--dangerously-skip-permissions" ./scripts/ralph-loop.sh
# Run it only inside a disposable container or VM when using --dangerously-skip-permissions.
set -euo pipefail
cd "$(dirname "$0")/.."

MAX_ITERATIONS=${MAX_ITERATIONS:-10}
SLEEP_BETWEEN=${SLEEP_BETWEEN:-5}
CLAUDE_FLAGS=${CLAUDE_FLAGS:-}

state() { sed -n 's/^## Current State: *\([A-Z_]*\).*/\1/p' progress.txt | head -1; }

command -v claude >/dev/null || { echo "[ralph] claude CLI not found" >&2; exit 1; }
[[ -f prompt.md && -f progress.txt ]] || { echo "[ralph] prompt.md or progress.txt missing" >&2; exit 1; }

for ((i = 1; i <= MAX_ITERATIONS; i++)); do
  case "$(state)" in
    COMPLETED) echo "[ralph] completed"; exit 0 ;;
    BLOCKED)   echo "[ralph] blocked, see '## Blocked on' in progress.txt" >&2; exit 1 ;;
  esac
  echo "[ralph] iteration $i/$MAX_ITERATIONS, state $(state), $(sed -n 's/^## Current milestone: *//p' progress.txt)"
  # shellcheck disable=SC2086
  claude -p "$(cat prompt.md)" $CLAUDE_FLAGS || echo "[ralph] iteration $i exited non-zero, continuing" >&2
  sleep "$SLEEP_BETWEEN"
done

echo "[ralph] reached MAX_ITERATIONS=$MAX_ITERATIONS, state $(state); run again to continue"
exit 2
