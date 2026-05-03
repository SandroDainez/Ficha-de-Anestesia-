#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_VERCEL_DIR="$ROOT_DIR/.vercel"
BUILD_DIR="$ROOT_DIR/build/web"
BUILD_VERCEL_DIR="$BUILD_DIR/.vercel"
Vercel_ENV_FILE="$ROOT_VERCEL_DIR/.env.production.local"

if [[ ! -f "$ROOT_VERCEL_DIR/project.json" ]]; then
  echo "Missing $ROOT_VERCEL_DIR/project.json. Link the root project with 'vercel link' first." >&2
  exit 1
fi

if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo ">>> Pulling production environment variables from Vercel..."
  vercel pull --yes --environment=production --cwd "$ROOT_DIR"
fi

if [[ -f "$Vercel_ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$Vercel_ENV_FILE"
  set +a
fi

if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "Missing SUPABASE_URL or SUPABASE_ANON_KEY for Flutter web build." >&2
  echo "Set them locally or configure them in Vercel before deploying production." >&2
  exit 1
fi

flutter build web \
  --no-wasm-dry-run \
  --dart-define="SUPABASE_URL=${SUPABASE_URL}" \
  --dart-define="SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}"

# Deploy a partir de build/: não usar o vercel.json da raiz (tem buildCommand/output
# para CI); aqui os ficheiros já estão compilados.
cp "$ROOT_DIR/scripts/vercel-for-prebuilt-web.json" "$BUILD_DIR/vercel.json"
cp "$ROOT_DIR/scripts/package-for-prebuilt-web.json" "$BUILD_DIR/package.json"

mkdir -p "$BUILD_VERCEL_DIR"
cp "$ROOT_VERCEL_DIR/project.json" "$BUILD_VERCEL_DIR/project.json"

vercel deploy --cwd "$BUILD_DIR" --prod --yes
