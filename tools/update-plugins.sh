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

lua_compiler=""
if command -v luac5.4 >/dev/null 2>&1; then
  lua_compiler=luac5.4
elif command -v luac >/dev/null 2>&1; then
  lua_compiler=luac
fi

validate_destination() {
  local destination=$1
  if [[ -z "$destination" || "$destination" = /* || "$destination" == *".."* ]]; then
    echo "Unsafe destination in manifest: ${destination:-<empty>}" >&2
    exit 1
  fi
}

validate_lua_tree() {
  local path=$1
  [[ -z "$lua_compiler" ]] && return 0

  if [[ -f "$path" && "$path" == *.lua ]]; then
    "$lua_compiler" -p "$path"
  elif [[ -d "$path" ]]; then
    while IFS= read -r -d '' file; do
      "$lua_compiler" -p "$file"
    done < <(find "$path" -type f -name '*.lua' -print0)
  fi
}

clone_cached_repo() {
  local source=$1
  local ref=$2
  local key
  key=$(printf '%s\n%s' "$source" "$ref" | sha256sum | cut -d' ' -f1)
  local checkout="$tmp_dir/repos/$key"

  if [[ ! -d "$checkout/.git" ]]; then
    mkdir -p "$tmp_dir/repos"
    git clone --quiet --depth 1 --branch "$ref" --single-branch "$source" "$checkout"
  fi

  printf '%s\n' "$checkout"
}

while IFS=$'\t' read -r kind source ref source_path destination; do
  [[ -z "${kind:-}" || "$kind" == \#* ]] && continue
  validate_destination "${destination:-}"

  target="$repo_root/$destination"
  echo "Updating $destination"

  case "$kind" in
    raw)
      staged="$tmp_dir/raw-$(printf '%s' "$destination" | sha256sum | cut -d' ' -f1)"
      curl --fail --location --silent --show-error --retry 3 --retry-delay 2 \
        --output "$staged" "$source"

      if [[ ! -s "$staged" ]]; then
        echo "Downloaded file is empty: $source" >&2
        exit 1
      fi

      validate_lua_tree "$staged"
      mkdir -p -- "$(dirname -- "$target")"
      install -m 0644 "$staged" "$target"
      ;;

    git)
      if [[ -z "${ref:-}" || "$ref" == "-" || -z "${source_path:-}" || "$source_path" == "-" || "$source_path" = /* || "$source_path" == *".."* ]]; then
        echo "Invalid git source entry for $destination" >&2
        exit 1
      fi

      checkout=$(clone_cached_repo "$source" "$ref")
      staged="$checkout/$source_path"
      if [[ ! -e "$staged" ]]; then
        echo "Git source path does not exist: $source_path" >&2
        exit 1
      fi

      validate_lua_tree "$staged"
      rm -rf -- "$target"
      mkdir -p -- "$(dirname -- "$target")"
      if [[ -d "$staged" ]]; then
        cp -a -- "$staged" "$target"
      else
        install -m 0644 "$staged" "$target"
      fi
      ;;

    *)
      echo "Unknown plugin source kind: $kind" >&2
      exit 1
      ;;
  esac
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
