#!/usr/bin/env bash
# Build Flutter web no ambiente Linux (Vercel). Clona o SDK stable uma vez por build.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FLUTTER_DIR="${HOME}/.cache/flutter-sdk-stable"

if [[ ! -x "${FLUTTER_DIR}/bin/flutter" ]]; then
  echo ">>> Instalando Flutter SDK (stable, shallow clone)..."
  rm -rf "${FLUTTER_DIR}"
  mkdir -p "$(dirname "${FLUTTER_DIR}")"
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "${FLUTTER_DIR}"
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"

flutter config --no-analytics
flutter precache --web
flutter pub get

build_args=(
  --release
  --no-wasm-dry-run
)

if [[ -n "${SUPABASE_URL:-}" || -n "${SUPABASE_ANON_KEY:-}" ]]; then
  if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_ANON_KEY:-}" ]]; then
    echo "Both SUPABASE_URL and SUPABASE_ANON_KEY must be defined for web builds." >&2
    exit 1
  fi
  build_args+=(
    "--dart-define=SUPABASE_URL=${SUPABASE_URL}"
    "--dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}"
  )
fi

flutter build web "${build_args[@]}"

# Deploys feitos com `vercel deploy --cwd build/web` precisam do vercel.json na pasta servida.
if [[ -f "${ROOT_DIR}/vercel.json" ]]; then
  cp "${ROOT_DIR}/vercel.json" "${ROOT_DIR}/build/web/vercel.json"
fi

echo ">>> build/web pronto."
