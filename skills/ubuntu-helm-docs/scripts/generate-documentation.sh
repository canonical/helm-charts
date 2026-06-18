#!/usr/bin/env bash
# generate-documentation.sh — Extract values table from a chart's values.yaml.
# Outputs a markdown table of: key | type | default | description
# Copilot uses this table as raw data when composing the full README.md.
#
# Usage: CHART_DIR=charts/myapp bash generate-documentation.sh
set -euo pipefail

CHART_DIR="${CHART_DIR:?CHART_DIR must be set}"
VALUES_FILE="$CHART_DIR/values.yaml"

if [ ! -f "$VALUES_FILE" ]; then
	echo "ERROR: values.yaml not found at $VALUES_FILE" >&2
	exit 1
fi

if ! command -v uv >/dev/null 2>&1; then
	echo "ERROR: uv is required but not found (run scripts/setup.sh --install)" >&2
	exit 1
fi

echo "| Key | Type | Default | Description |"
echo "|-----|------|---------|-------------|"

# Use ruamel.yaml for correct YAML parsing; regex for comment extraction
uv run --with ruamel.yaml python3 <<'PYEOF'
import sys, os, re
from ruamel.yaml import YAML
from ruamel.yaml.comments import CommentedMap, CommentedSeq

values_file = os.path.join(os.environ['CHART_DIR'], 'values.yaml')

# --- Pass 1: extract descriptions from structured comment annotations ---
# Handles bitnami @param and helm-docs "# --" conventions.
param_map = {}
with open(values_file) as f:
    raw_lines = f.readlines()

prev_helmdocs = None  # holds a "# -- desc" pending for the next key line
for line in raw_lines:
    stripped = line.strip()

    # Bitnami: ## @param dotted.key [options] Description text
    m = re.match(r'^##?\s*@param\s+(\S+)(?:\s+\[.*?\])?\s+(.*)', stripped)
    if m:
        desc = m.group(2).strip()
        if desc:
            param_map[m.group(1)] = desc
        continue

    # helm-docs: # -- Description (always on the line above the key)
    m = re.match(r'^#\s*--\s+(.*)', stripped)
    if m:
        prev_helmdocs = m.group(1).strip()
        continue

    # If previous line was a helm-docs comment, attach to this key
    if prev_helmdocs and ':' in stripped and not stripped.startswith('#'):
        key = stripped.split(':', 1)[0].strip().strip('-').strip()
        if key:
            param_map[key] = prev_helmdocs
    prev_helmdocs = None

# --- Pass 2: parse YAML structure and extract inline comments ---
yaml_parser = YAML()
with open(values_file) as f:
    values = yaml_parser.load(f) or {}


def get_inline_comment(node, key):
    """Get the inline comment (same line) for a key in a CommentedMap."""
    if not isinstance(node, CommentedMap):
        return None
    if not hasattr(node, 'ca') or key not in node.ca.items:
        return None
    item_comments = node.ca.items[key]
    # Index 2 = inline comment token
    if len(item_comments) > 2 and item_comments[2] is not None:
        token = item_comments[2]
        if hasattr(token, 'value'):
            text = token.value.strip().lstrip('#').strip()
            if text and not text.startswith('@'):
                return text
    return None


def flatten(node, prefix=''):
    """Recursively flatten YAML into (key, value, inline_comment) tuples."""
    items = []
    if isinstance(node, (CommentedMap, dict)):
        for k in node:
            v = node[k]
            full = f'{prefix}.{k}' if prefix else str(k)
            comment = get_inline_comment(node, k) if isinstance(node, CommentedMap) else None
            if isinstance(v, (dict, list)):
                items.extend(flatten(v, full))
            else:
                items.append((full, v, comment))
    elif isinstance(node, (CommentedSeq, list)):
        for i, v in enumerate(node):
            full = f'{prefix}[{i}]'
            if isinstance(v, (dict, list)):
                items.extend(flatten(v, full))
            else:
                items.append((full, v, None))
    return items


rows = flatten(values)
for key, val, inline_comment in rows:
    val_type = type(val).__name__
    if val_type == 'NoneType':
        val_type = 'string'
        val = '""'
    elif val_type == 'bool':
        val = str(val).lower()
    elif val_type == 'int':
        val_type = 'integer'

    # Priority: @param / helm-docs annotation > inline comment > (inferred)
    description = param_map.get(key) or inline_comment or '(inferred)'
    print(f'| `{key}` | `{val_type}` | `{val}` | {description} |')
PYEOF
