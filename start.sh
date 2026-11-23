#!/bin/bash
# Railway start script for Kirara AI.
# - seeds the data volume on first boot (same as upstream's docker/start.sh)
# - writes the LLM backend, HTTP API and admin password from Railway variables
# - exits non-zero whenever the app stops without being asked to, so Railway restarts it
set -euo pipefail
cd /app
DATA=/app/data
mkdir -p "$DATA"

if [ -z "$(ls -A "$DATA" 2>/dev/null | grep -v '^lost+found$' || true)" ]; then
  echo "[railway] empty data volume: copying default data"
  cp -r /tmp/data/. "$DATA"
fi
# keep upstream's defaults for anything missing (e.g. after an upstream update adds files)
for d in dispatch_rules workflows; do
  [ -e "$DATA/$d" ] || cp -r "/tmp/data/$d" "$DATA/$d"
done
mkdir -p "$DATA/web" "$DATA/memory" "$DATA/media"

# Plugins installed from the web UI go into this venv on the volume, so they survive redeploys.
if [ ! -x "$DATA/venv/bin/python" ]; then
  echo "[railway] creating plugin venv on the volume"
  python -m venv "$DATA/venv" --system-site-packages
fi
# shellcheck disable=SC1091
source "$DATA/venv/bin/activate"
if [ -d "$DATA/venv/lib" ] && ls "$DATA"/venv/lib/python*/site-packages/kirara_ai >/dev/null 2>&1; then
  echo "[railway] WARNING: a kirara-ai copy installed from the web UI's updater is shadowing this image's version."
  echo "[railway] Template updates from Railway won't take effect until it is removed (pip uninstall kirara-ai inside the venv)."
fi

# Admin password: set once from ADMIN_PASSWORD so the first visitor can't claim the instance.
if [ ! -s "$DATA/web/password.hash" ]; then
  if [ -z "${ADMIN_PASSWORD:-}" ]; then
    echo "[railway] ERROR: ADMIN_PASSWORD is empty and no admin password is set yet; refusing to start an unlocked instance." >&2
    exit 1
  fi
  python - <<'PY'
import os
from kirara_ai.web.auth.utils import hash_password
path = "/app/data/web/password.hash"
with open(path + ".tmp", "wb") as f:
    f.write(hash_password(os.environ["ADMIN_PASSWORD"]))
os.replace(path + ".tmp", path)
print("[railway] admin password set from ADMIN_PASSWORD")
PY
fi

python /app/railway/configure.py

term=0
on_term() {
  [ "$term" = 1 ] && return
  term=1
  [ -n "${child:-}" ] || return
  kill -TERM "$child" 2>/dev/null || true
  # Kirara AI v3.2.1 often doesn't finish a graceful stop; its own handler forces
  # an exit on the third signal. Data is already on disk (SQLite + memory files).
  ( sleep "${STOP_GRACE_SECONDS:-8}"; kill -TERM "$child" 2>/dev/null; sleep 1; kill -TERM "$child" 2>/dev/null ) &
}
trap on_term TERM INT

setsid python -m kirara_ai -H 0.0.0.0 -p "${PORT:-8080}" &
child=$!
set +e
while :; do
  wait "$child"; code=$?
  # a trapped signal interrupts wait while the app is still shutting down
  kill -0 "$child" 2>/dev/null || break
done
set -e
if [ "$term" = 1 ]; then
  echo "[railway] stopped on request"
  exit 0
fi
echo "[railway] Kirara AI exited unexpectedly (code $code); exiting non-zero so Railway restarts it" >&2
if [ "$code" = 0 ]; then exit 1; fi
exit "$code"
