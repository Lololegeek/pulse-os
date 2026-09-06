#!/usr/bin/env python3
from pathlib import Path
import re
import sys

roots = [
    Path('Containerfile'), Path('Containerfile.nvidia'), Path('installer/Containerfile'),
    Path('rootfs/etc'), Path('rootfs/usr/lib/systemd'),
]
patterns = {
    'mitigations=off': re.compile(r'(?<![A-Za-z0-9_.-])mitigations=off(?![A-Za-z0-9_.-])'),
    'nopti': re.compile(r'(?<![A-Za-z0-9_.-])nopti(?![A-Za-z0-9_.-])'),
    'nospectre': re.compile(r'(?<![A-Za-z0-9_.-])nospectre(?:_v1|_v2)?(?![A-Za-z0-9_.-])'),
    'noibrs': re.compile(r'(?<![A-Za-z0-9_.-])noibrs(?![A-Za-z0-9_.-])'),
    'nowatchdog': re.compile(r'(?<![A-Za-z0-9_.-])nowatchdog(?![A-Za-z0-9_.-])'),
    'GPU overclock unlock': re.compile(r'apply_gpu_optimisations\s*=\s*accept-responsibility'),
    'AMDGPU full ppfeaturemask': re.compile(r'amdgpu\.ppfeaturemask\s*=\s*0xffffffff', re.I),
}

def iter_files(p: Path):
    if p.is_file():
        yield p
    elif p.is_dir():
        yield from (x for x in p.rglob('*') if x.is_file())

bad = []
for root in roots:
    for path in iter_files(root):
        try:
            text = path.read_text(errors='ignore')
        except OSError:
            continue
        for lineno, raw in enumerate(text.splitlines(), 1):
            stripped = raw.lstrip()
            if stripped.startswith('#') or stripped.startswith(';'):
                continue
            # Remove shell/config trailing comments where practical.
            line = raw.split(' #', 1)[0]
            for name, rx in patterns.items():
                if rx.search(line):
                    bad.append((str(path), lineno, name, raw.strip()))

if bad:
    for path, line, name, content in bad:
        print(f'{path}:{line}: unsafe setting ({name}): {content}', file=sys.stderr)
    sys.exit(1)
print('safety policy scan: clean')
