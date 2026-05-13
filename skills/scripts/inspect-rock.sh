#!/usr/bin/env bash
# inspect-rock.sh — Extract the Pebble plan from a rock.
# Usage:
#   IMAGE_REF=ghcr.io/canonical/myapp:1.0.0 bash inspect-rock.sh
#
# Exit codes:
#   0 — success; PebblePlan YAML printed to stdout
#   1 — image not found / access error
#   2 — no Pebble entrypoint found / no plan; empty plan printed + warning on stderr
set -euo pipefail

if [ -z "${IMAGE_REF:-}" ]; then
  echo "ERROR: Set IMAGE_REF" >&2
  exit 1
fi

# Detect docker or podman
ENGINE=""
if command -v docker >/dev/null 2>&1; then
    ENGINE="docker"
elif command -v podman >/dev/null 2>&1; then
    ENGINE="podman"
else
    echo "ERROR: Neither docker nor podman is installed." >&2
    exit 1
fi

# Pull the image if it's not present locally
if ! $ENGINE inspect "$IMAGE_REF" >/dev/null 2>&1; then
    $ENGINE pull "$IMAGE_REF" >&2 || {
        echo "ERROR: Failed to pull image: $IMAGE_REF" >&2
        exit 1
    }
fi

# Find the OCI entrypoint
ENTRYPOINT=$($ENGINE inspect --format '{{json .Config.Entrypoint}}' "$IMAGE_REF" 2>/dev/null || echo "[]")

# Evaluate Entrypoint
if [[ "$ENTRYPOINT" != *"pebble"* ]]; then
    echo "WARNING: No pebble entrypoint found in image" >&2
    printf 'pebble_plan:\n  services: {}\n  checks: {}\n  source_layers: []\n'
    exit 2
fi

if [[ "$ENTRYPOINT" == *"--args"* ]]; then
    $ENGINE run --rm "$IMAGE_REF" \; plan || exit_code=$?
else
    $ENGINE run --rm "$IMAGE_REF" plan || exit_code=$?
fi

exit 0
