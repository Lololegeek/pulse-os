#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0
say() { printf '%-58s %s\n' "$1" "$2"; }

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
  src/CMakeLists.txt \
  src/libpulseos/include/pulseos/process.hpp \
  src/libpulseos/process.cpp \
  src/pulse-perfd/main.cpp \
  kernel/config/pulseos-x86_64.fragment \
  scheduler/pulse-scx/pulse_scx.bpf.c \
  rootfs/usr/local/bin/pulseos-session \
  rootfs/usr/local/bin/pulseosctl \
  rootfs/usr/libexec/pulseos/gamingd \
  rootfs/usr/libexec/pulseos/performance-agent \
  rootfs/etc/gamemode.ini \
  rootfs/usr/lib/systemd/system/pulseos-scx.service \
  rootfs/usr/lib/systemd/system/pulseos-performance-agent.service; do
  if [[ -s "$f" ]]; then say "$f" PRESENT; else say "$f" MISSING; fail=1; fi
done

# Compile the native C++ control plane on every CI run. pulse-scx is kept out of
# this build until its loader pins a tested sched_ext ABI/header set.
if command -v cmake >/dev/null 2>&1 && command -v c++ >/dev/null 2>&1; then
  native_build=/tmp/pulseos-native-build
  rm -rf "$native_build"
  if cmake -S src -B "$native_build" -G Ninja -DCMAKE_BUILD_TYPE=Release >/tmp/pulseos-cmake.log 2>&1 && \
     cmake --build "$native_build" --parallel >/tmp/pulseos-native-build.log 2>&1; then
    say 'native C++ build' OK
  else
    cat /tmp/pulseos-cmake.log /tmp/pulseos-native-build.log 2>/dev/null >&2 || true
    say 'native C++ build' FAIL
    fail=1
  fi
else
  say 'native C++ build' 'SKIPPED (compiler/cmake unavailable)'
fi

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
