#!/usr/bin/env bash
# Builds the offline web version (for iPad/iPhone Safari and other browsers).
#   tool/build_web.sh [base-href]      e.g. tool/build_web.sh /Mathanwer/
# Output: build/web  (static files; host on any HTTPS static host)
set -euo pipefail
BASE="${1:-/}"
flutter build web --release --no-web-resources-cdn --base-href "$BASE"
cd build/web
# Everything needed offline (both CanvasKit builds: Safari uses canvaskit/,
# Chrome uses canvaskit/chromium/), minus renderers this JS build never loads.
python3 - <<'PY'
import hashlib, json, os
files = []
h = hashlib.sha256()
for root, _, names in os.walk('.'):
    for n in sorted(names):
        path = os.path.relpath(os.path.join(root, n), '.').replace(os.sep, '/')
        if path in ('sw.js', 'offline_files.json', 'flutter_service_worker.js'):
            continue
        if ('skwasm' in path or 'wimp' in path or 'webparagraph' in path
                or path.endswith('.map') or path.endswith('.symbols')):
            continue
        files.append(path)
        with open(path, 'rb') as f:
            h.update(path.encode()); h.update(f.read())
files.sort()
files.insert(0, '.')
json.dump(files, open('offline_files.json', 'w'), indent=0)
version = h.hexdigest()[:12]
sw = open('sw.js').read().replace('__VERSION__', version)
open('sw.js', 'w').write(sw)
total = sum(os.path.getsize(f) for f in files if f != '.')
print(f'offline files: {len(files)}  total {total/1e6:.1f} MB  version {version}')
PY
