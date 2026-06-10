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

if ! command -v python3 >/dev/null 2>&1; then
	echo "ERROR: python3 is required but not found" >&2
	exit 1
fi

echo "| Key | Type | Default | Description |"
echo "|-----|------|---------|-------------|"

# Use python3 to parse YAML and extract flat key/value/comment triples
uv run python3 <<'PYEOF'
import yaml, sys, os, re

values_file = os.path.join(os.environ['CHART_DIR'], 'values.yaml')

# Read raw lines to capture inline comments
with open(values_file) as f:
    raw_lines = f.readlines()

# Build a comment map: key_path -> comment
# Simple approach: look for lines with `# description` comments
comment_map = {}
current_path = []
indent_stack = []

for line in raw_lines:
    stripped = line.rstrip('\n')
    indent = len(line) - len(line.lstrip())

    # Check for inline comment
    comment = ''
    if '#' in stripped:
        parts = stripped.split('#', 1)
        comment = parts[1].strip()
        stripped = parts[0].rstrip()

    if ':' in stripped and not stripped.strip().startswith('-'):
        key = stripped.strip().split(':', 1)[0].strip()
        if key:
            # Manage path
            while indent_stack and indent_stack[-1][0] >= indent:
                indent_stack.pop()
                if current_path:
                    current_path.pop()
            if key:
                current_path.append(key)
                indent_stack.append((indent, key))
                full_key = '.'.join(current_path)
                if comment:
                    comment_map[full_key] = comment

# Now load YAML and flatten
with open(values_file) as f:
    values = yaml.safe_load(f) or {}

def flatten(d, prefix=''):
    items = []
    if isinstance(d, dict):
        for k, v in d.items():
            full = f'{prefix}.{k}' if prefix else k
            if isinstance(v, (dict, list)):
                items.extend(flatten(v, full))
            else:
                items.append((full, v))
    elif isinstance(d, list):
        for i, v in enumerate(d):
            full = f'{prefix}[{i}]'
            if isinstance(v, (dict, list)):
                items.extend(flatten(v, full))
            else:
                items.append((full, v))
    return items

rows = flatten(values)
for key, val in rows:
    val_type = type(val).__name__
    if val_type == 'NoneType':
        val_type = 'string'
        val = '""'
    elif val_type == 'bool':
        val = str(val).lower()
    elif val_type == 'int':
        val_type = 'integer'

    description = comment_map.get(key, '(inferred)')
    print(f'| `{key}` | `{val_type}` | `{val}` | {description} |')
PYEOF
