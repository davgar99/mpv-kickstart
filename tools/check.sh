#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

bash -n tools/update-plugins.sh tools/check.sh
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck tools/update-plugins.sh tools/check.sh
fi

if command -v luac5.4 >/dev/null 2>&1; then
  lua_compiler=luac5.4
elif command -v luac >/dev/null 2>&1; then
  lua_compiler=luac
else
  echo "Lua compiler not found" >&2
  exit 1
fi

mapfile -t lua_files < <(find scripts -type f -name '*.lua' -print | sort)
if (( ${#lua_files[@]} == 0 )); then
  echo "No Lua plugins found" >&2
  exit 1
fi

for file in "${lua_files[@]}"; do
  "$lua_compiler" -p "$file"
done

manifest=.github/plugin-sources.tsv
declare -A seen_destinations=()
manifest_entries=0

while IFS=$'\t' read -r kind source ref source_path destination; do
  [[ -z "${kind:-}" || "$kind" == \#* ]] && continue
  ((manifest_entries += 1))

  if [[ "$kind" != raw && "$kind" != git ]]; then
    echo "Unknown plugin source kind: $kind" >&2
    exit 1
  fi
  if [[ -z "${source:-}" || -z "${destination:-}" || "$destination" = /* || "$destination" == *".."* ]]; then
    echo "Invalid plugin manifest entry for ${destination:-<empty>}" >&2
    exit 1
  fi
  if [[ -n "${seen_destinations[$destination]:-}" ]]; then
    echo "Plugin manifest contains duplicate destination: $destination" >&2
    exit 1
  fi
  seen_destinations[$destination]=1

  if [[ "$kind" == git && ( -z "${ref:-}" || "$ref" == - || -z "${source_path:-}" || "$source_path" == - || "$source_path" = /* || "$source_path" == *".."* ) ]]; then
    echo "Incomplete or unsafe git plugin entry for $destination" >&2
    exit 1
  fi

  if [[ ! -e "$destination" ]]; then
    echo "Manifest destination is missing: $destination" >&2
    exit 1
  fi
  if [[ -f "$destination" && ! -s "$destination" ]]; then
    echo "Manifest destination is empty: $destination" >&2
    exit 1
  fi
done < "$manifest"

if (( manifest_entries == 0 )); then
  echo "Plugin source manifest is empty or malformed" >&2
  exit 1
fi

# Catch stale ModernZ options when upstream removes or renames a setting.
python3 <<'PY'
from pathlib import Path
import re

script = Path('scripts/modernz.lua').read_text()
config = Path('script-opts/modernz.conf').read_text()

match = re.search(r'local user_opts\s*=\s*\{(.*?)\n\}', script, re.DOTALL)
if not match:
    raise SystemExit('Could not find ModernZ user_opts table')

valid = set(re.findall(r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=', match.group(1), re.MULTILINE))
configured = set()
for raw_line in config.splitlines():
    line = raw_line.strip()
    if not line or line.startswith('#') or '=' not in line:
        continue
    key = line.split('=', 1)[0].strip()
    configured.add(key)

unknown = sorted(configured - valid)
if unknown:
    raise SystemExit('Unknown ModernZ options: ' + ', '.join(unknown))
PY

# Parse mpv.conf with mpv when available. The timeout is expected because idle mode stays open.
if command -v mpv >/dev/null 2>&1; then
  log=$(mktemp)
  trap 'rm -f "$log"' EXIT
  set +e
  timeout 3s mpv --no-config --include="$repo_root/mpv.conf" --idle=yes --vo=null --ao=null \
    --msg-level=all=warn >"$log" 2>&1
  status=$?
  set -e

  if [[ $status -ne 0 && $status -ne 124 ]]; then
    cat "$log" >&2
    exit "$status"
  fi

  if grep -Eiq 'error parsing option|failed to set option|unknown option' "$log"; then
    cat "$log" >&2
    exit 1
  fi
fi

echo "All repository checks passed."
