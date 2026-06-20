#!/usr/bin/env bash
# Sync the canonical data/stations.json into the MetroData package resources.
# The repo root file is the single source of truth; this copies it so the Swift
# package can bundle it. CI verifies the two stay identical.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cp "$ROOT/data/stations.json" "$ROOT/Packages/MetroData/Sources/MetroData/Resources/stations.json"
echo "Synced data/stations.json → Packages/MetroData/Sources/MetroData/Resources/"
