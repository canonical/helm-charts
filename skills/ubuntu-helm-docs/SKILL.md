---
name: ubuntu-helm-docs
description: >-
  Generate or update README.md documentation for Helm charts in this project.
  Extracts all values from values.yaml, describes deployed resources, and
  produces a complete README with architecture, installation, configuration
  table, and upgrade sections. Use when: documenting a chart, generating a
  README, updating docs after adding features or values. Trigger phrases:
  "document chart", "generate README", "update docs for chart",
  "generate documentation", "write README for chart".
argument-hint: '<chart-path>'
---

# Ubuntu Helm Docs

Generate or update `README.md` for a Helm chart in `<chart-path>/`.

## Prerequisites

Run `scripts/setup.sh` to verify required tools (uv, python3 with pyyaml).

## Workflow

### Step 1 — Extract values table

```bash
CHART_DIR=<chart-path> bash scripts/generate-documentation.sh
```

The script parses `values.yaml` and outputs a markdown table:

```
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| image.repository | string | docker.io/ubuntu/nginx | Container image repository |
| ...
```

### Step 2 — Read chart metadata

Read `<chart-path>/Chart.yaml` for:
- `name` — chart name
- `description` — chart description (includes the rock name and rock description)
- `version` — chart version
- `appVersion` — application version

### Step 3 — Inspect templates

Read `<chart-path>/templates/` to identify deployed resources (Deployment, StatefulSet, Service, Ingress, ServiceAccount, ConfigMap, etc.).

Note any:
- Pebble-wired probes (exec `/bin/pebble health`)
- Security constraints (PSS-Restricted securityContext)
- Special volume mounts (readOnlyRootFilesystem workarounds, config volumes)

### Step 4 — Compose README.md

Write `<chart-path>/README.md` following this structure:

```markdown
# <chart-name>

<chart description from Chart.yaml>

## Architecture

<brief description of deployed resources: Deployment, Service, ServiceAccount, etc.>
<note Pebble-wired probes, volume mounts, or security constraints if present>

## Prerequisites

- Kubernetes 1.29+
- Helm 3.x

## Installation

\```bash
helm install my-<chart-name> <chart-path>/
\```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
<values table from Step 1>

## Upgrading

\```bash
helm upgrade my-<chart-name> <chart-path>/
\```
```

### Step 5 — Fill missing descriptions

**Every value MUST have a non-empty description.** If the script marks a value as `(inferred)`:
- Generate a description from the value name and type context
- Example: `image.repository` → "Container image repository"
- Example: `runAsUser` → "UID to run the container as (derived from the rock's OCI user)"
- Example: `livenessProbe.httpGet.path` → "HTTP path for the liveness health check"

No value may be left with an empty or `(inferred)` description in the final README.

## Quality checks

- [ ] Every value in `values.yaml` appears in the Configuration table
- [ ] No description is empty or says `(inferred)`
- [ ] Architecture section lists all template resources
- [ ] Installation command uses the correct chart path
