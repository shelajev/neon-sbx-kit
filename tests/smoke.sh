#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
spec="$repo_dir/spec.yaml"

grep -q '^schemaVersion: "2"$' "$spec"
grep -q '^kind: mixin$' "$spec"
grep -q '^  - service: neon$' "$spec"
grep -q '^      name: NEON_API_KEY$' "$spec"
grep -q '^        - domain: console.neon.tech$' "$spec"
grep -q '"neon@${{ kit.args.neon-version }}"' "$spec"

bash -n "$repo_dir/run.sh"

if command -v sbx >/dev/null 2>&1; then
  sbx kit validate "$repo_dir"
  sbx kit inspect "$repo_dir" >/dev/null
fi

echo "Neon kit smoke checks passed"
