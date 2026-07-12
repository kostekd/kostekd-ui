#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo ""
echo "==> [1/4] git checkout main"
git checkout main

echo ""
echo "==> [2/4] git pull"
git pull --ff-only

echo ""
echo "==> [3/4] docker compose build"
docker compose build

echo ""
echo "==> [4/4] docker compose up"
docker compose up -d --remove-orphans --force-recreate

echo ""
echo "==> done"
echo ""
