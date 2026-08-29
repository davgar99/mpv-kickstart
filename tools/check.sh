#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

bash -n tools/update-plugins.sh tools/check.sh

if command -v luac5.4 >/dev/null 2>&1; then
  lua_compiler=luac5.4
elif command -v luac >/dev/null 2>&1; then
  lua_compiler=luac
else
  echo "Lua compiler not found" >&2
  exit 1
fi

mapfile -t lua_files < <(find scripts -maxdepth 1 -type f -name '*.lua' -print | sort)
if (( ${#lua_files[@]} == 0 )); then
  echo "No Lua plugins found" >&2
  exit 1
fi

for file in "${lua_files[@]}"; do
  "$lua_compiler" -p "$file"
done

manifest=.github/plugin-sources.tsv
mapfile -t destinations < <(awk -F '\t' '!/^#/ && NF >= 2 { print $2 }' "$manifest")
if (( ${#destinations[@]} == 0 )); then
  echo "Plugin source manifest is empty" >&2
  exit 1
fi

if [[ $(printf '%s\n' "${destinations[@]}" | sort | uniq -d | wc -l) -ne 0 ]]; then
  echo "Plugin manifest contains duplicate destinations" >&2
  exit 1
fi

for destination in "${destinations[@]}"; do
  if [[ ! -s "$destination" ]]; then
    echo "Manifest destination is missing or empty: $destination" >&2
    exit 1
  fi
done

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
