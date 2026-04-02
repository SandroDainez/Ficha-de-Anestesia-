#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_VERCEL_DIR="$ROOT_DIR/.vercel"
BUILD_DIR="$ROOT_DIR/build/web"
BUILD_VERCEL_DIR="$BUILD_DIR/.vercel"

if [[ ! -f "$ROOT_VERCEL_DIR/project.json" ]]; then
  echo "Missing $ROOT_VERCEL_DIR/project.json. Link the root project with 'vercel link' first." >&2
  exit 1
fi

flutter build web --no-wasm-dry-run

mkdir -p "$BUILD_VERCEL_DIR"
cp "$ROOT_VERCEL_DIR/project.json" "$BUILD_VERCEL_DIR/project.json"

vercel deploy --cwd "$BUILD_DIR" --prod --yes
