#!/usr/bin/env bash
#
# Claude Code status line: name the local dev instances running from *this*
# worktree, and print nothing anywhere else.
#
# PM2 runs as a single per-user daemon (~/.pm2), and instance numbers are
# allocated globally by port probing, so `pm2 list` from any checkout shows
# instances belonging to every other checkout with no hint of which is which.
# This walks PM2's pidfiles and claims only the instances whose live processes
# have this repo root as their cwd.
#
# Deliberately no `pm2` subprocess: `pm2 jlist` costs ~180ms, spawns node, and
# *starts the daemon if it is down* — an unacceptable state change from a status
# line. The pidfile walk is a few ms and strictly read-only.
#
# Usage:
#   <status-line JSON on stdin>   the way Claude Code invokes it
#   --root PATH                   same answer, for running by hand

set -euo pipefail

# The five monolith apps defined by local/pm2.config.js. Filtering to these
# excludes integrations-platform's i{N}-tms / i{N}-ac, which share this daemon
# and the same i{N} namespace scheme (see local/which-instance.sh).
SERVICES=(server client admin public pages)

if [ "${1-}" = "--root" ]; then
  root="${2-}"
  [ -n "$root" ] || exit 0
else
  payload="$(cat)"
  dir="$(printf '%s' "$payload" | jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null || true)"
  [ -n "$dir" ] || exit 0
  root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "$root" ] || exit 0
fi

# /proc/*/cwd is a physical path, but a worktree can be reached via symlinks,
# so resolve this side to match.
root="$(cd -P "$root" 2>/dev/null && pwd || true)"
[ -n "$root" ] || exit 0

# Directory gate: local/pm2.config.js is what defines the i{N}-* apps, so its
# presence is exactly the condition under which anything below means something.
# Silent in every other project; needs nothing hardcoded per checkout.
[ -f "$root/local/pm2.config.js" ] || exit 0

PIDS_DIR="${PM2_HOME:-$HOME/.pm2}/pids"
[ -d "$PIDS_DIR" ] || exit 0

declare -A live=()
declare -A owned=()

for f in "$PIDS_DIR"/i*.pid; do
  [ -e "$f" ] || continue

  base="${f##*/}"
  base="${base%.pid}"
  # i{N}-{svc}-{pm_id}
  [[ $base =~ ^i([0-9]+)-([a-z]+)-[0-9]+$ ]] || continue
  n="${BASH_REMATCH[1]}"
  svc="${BASH_REMATCH[2]}"

  case " ${SERVICES[*]} " in
    *" $svc "*) ;;
    *) continue ;;
  esac

  # `read` builtin rather than cat: this runs per pidfile on every refresh.
  pid=""
  read -r pid < "$f" 2>/dev/null || true
  [[ $pid =~ ^[0-9]+$ ]] || continue
  # Stale pidfiles outlive their process.
  [ -d "/proc/$pid" ] || continue

  cwd="$(readlink "/proc/$pid/cwd" 2>/dev/null || true)"
  [ -n "$cwd" ] || continue
  # i{N}-pages is configured with cwd: "pages/", so its live cwd is <root>/pages.
  cwd="${cwd%/pages}"

  [ "$cwd" = "$root" ] || continue

  owned["$n"]=1
  live["$n|$svc"]=1
done

[ "${#owned[@]}" -gt 0 ] || exit 0

row=""
degraded=0
while read -r n; do
  row+=" i$n"
  for svc in "${SERVICES[@]}"; do
    # A stopped app leaves no pidfile at all, so absence is the only signal
    # available — and autorestart:false on all five makes "stopped" a real,
    # common state rather than a fault.
    if [ -z "${live["$n|$svc"]-}" ]; then
      row+=" -$svc"
      degraded=1
    fi
  done
done < <(printf '%s\n' "${!owned[@]}" | sort -n)

if [ "$degraded" -eq 1 ]; then
  colour=33 # yellow: something this worktree started is not running
else
  colour=32 # green: all five up
fi

printf '\033[%dm⬢%s\033[0m\n' "$colour" "$row"
