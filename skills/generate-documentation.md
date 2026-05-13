# Skill: generate-documentation

**Purpose**: Read a generated Helm chart directory and produce a comprehensive `README.md` documenting the chart's architecture, all configurable values with descriptions, and usage instructions.

## Script (for values extraction)

`skills/scripts/generate-documentation.sh`

## Workflow

1. Run `skills/scripts/generate-documentation.sh` with `CHART_DIR` set
2. Read the script's stdout — a markdown table of values with keys, types, defaults, and comment-derived descriptions
3. Read `charts/<chart-name>/Chart.yaml` for chart name, description, and version
4. Read `charts/<chart-name>/templates/` to understand the deployed resources
5. Compose and write `charts/<chart-name>/README.md`

## README.md structure

```markdown
# <chart-name>

<chart description from Chart.yaml>

## Architecture

<brief description of deployed resources: Deployment, Service, ServiceAccount, etc.>
<note any Pebble-wired probes, special volume mounts, or security constraints>

## Prerequisites

- Kubernetes 1.29+
- Helm 3.x

## Installation

\```bash
helm install <chart-name> charts/<chart-name>/
\```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
<values table from script output>

## Upgrading

\```bash
helm upgrade <chart-name> charts/<chart-name>/
\```
```

## Values description rule

**Every value MUST have a non-empty description.** If the script marks a value as `(inferred)`:
- Generate a description from the value name and type context
- Example: `image.repository` → "Container image repository"
- Example: `runAsUser` → "UID to run the container as (derived from Pebble service user)"
- Example: `livenessProbe.httpGet.path` → "HTTP path for the liveness health check"

No value may be left with an empty or `(inferred)` description in the final README.
