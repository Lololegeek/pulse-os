#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0
say() { printf '%-50s %s\n' "$1" "$2"; }

mapfile -t bash_files < <(find scripts rootfs -type f -print0 | xargs -0 grep -Il '^#!.*bash' | sort)
for f in "${bash_files[@]}"; do
  if bash -n "$f"; then say "$f" OK; else say "$f" FAIL; fail=1; fi
done

mapfile -t py_files < <(find rootfs -type f -print0 | xargs -0 grep -Il '^#!.*python' | sort)
for f in "${py_files[@]}"; do
  if PYTHONPYCACHEPREFIX=/tmp/pulseos-pycache python3 -m py_compile "$f"; then say "$f" OK; else say "$f" FAIL; fail=1; fi
done

for f in \
  Containerfile installer/Containerfile \
  rootfs/usr/local/bin/pulseos-session \
  rootfs/usr/local/bin/pulseosctl \
  rootfs/usr/libexec/pulseos/gamingd \
  rootfs/usr/libexec/pulseos/performance-agent \
  rootfs/etc/gamemode.ini \
  rootfs/usr/lib/systemd/system/pulseos-scx.service; do
  if [[ -s "$f" ]]; then say "$f" PRESENT; else say "$f" MISSING; fail=1; fi
done

# Hard-fail on dangerous benchmark-cheat/security-disable knobs.
if python3 scripts/check-safety.py; then
  say 'unsafe tuning scan' CLEAN
else
  fail=1
fi

# No fixed installer credentials. (The live Anaconda root account is deliberately
# passwordless only inside the ephemeral installer environment.)
if grep -RInE --exclude='verify.sh' '(^|[^A-Za-z])(rootpw|user).*--password=' installer rootfs >/tmp/pulseos-creds 2>/dev/null; then
  cat /tmp/pulseos-creds >&2
  echo 'possible fixed install credential found' >&2
  fail=1
else
  say 'fixed install credential scan' CLEAN
fi

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "${bash_files[@]}" || fail=1
else
  say 'shellcheck' 'SKIPPED (not installed)'
fi

exit "$fail"
