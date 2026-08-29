#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
manifest="$repo_root/.github/plugin-sources.tsv"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

if [[ ! -f "$manifest" ]]; then
  echo "Missing plugin source manifest: $manifest" >&2
  exit 1
fi

while IFS=$'\t' read -r url destination; do
  [[ -z "${url:-}" || "$url" == \#* ]] && continue

  if [[ -z "${destination:-}" || "$destination" = /* || "$destination" == *".."* ]]; then
    echo "Unsafe destination in manifest: ${destination:-<empty>}" >&2
    exit 1
  fi

  target="$repo_root/$destination"
  staged="$tmp_dir/$(basename -- "$destination")"

  echo "Updating $destination"
  curl --fail --location --silent --show-error --retry 3 --retry-delay 2 \
    --output "$staged" "$url"

  if [[ ! -s "$staged" ]]; then
    echo "Downloaded file is empty: $url" >&2
    exit 1
  fi

  if command -v luac5.4 >/dev/null 2>&1; then
    luac5.4 -p "$staged"
  elif command -v luac >/dev/null 2>&1; then
    luac -p "$staged"
  fi

  mkdir -p -- "$(dirname -- "$target")"
  install -m 0644 "$staged" "$target"
done < "$manifest"

# Preserve local customization while migrating options that upstream ModernZ removed or renamed.
modernz_conf="$repo_root/script-opts/modernz.conf"
if [[ -f "$modernz_conf" ]]; then
  python3 - "$modernz_conf" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
text = text.replace(
    '# set layout: "modern" or "modern-compact"\nlayout=modern\n',
    '# set layout: default, compact, mini, seekbar\nlayout=default\n',
)
text = text.replace(
    '# enable continuous skipping when holding down chapter skip buttons\nchapter_softrepeat=yes\n',
    '',
)
path.write_text(text)
PY
fi
