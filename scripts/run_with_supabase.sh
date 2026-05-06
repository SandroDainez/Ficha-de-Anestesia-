#!/bin/bash
# Script to run the Flutter app with Supabase configuration via dart-define
# Usage: ./scripts/run_with_supabase.sh <SUPABASE_URL> <SUPABASE_ANON_KEY>

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <SUPABASE_URL> <SUPABASE_ANON_KEY>"
  exit 1
fi

SUPABASE_URL="$1"
SUPABASE_ANON_KEY="$2"

flutter run \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
