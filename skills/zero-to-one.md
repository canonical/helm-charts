# Skill: zero-to-one

**Purpose**: Entry point for the Zero-to-One chart generation workflow. Encapsulates all steps to produce a minimal, tested, documented Helm chart from scratch.

## Trigger

Natural language: "Generate a minimal Helm chart for application `<name>` [using Rock image `<ref>`] [output to `<dir>`]"

## Complete workflow

Execute each step in order. Do not proceed to the next step if the current step fails.

### Step 1 — Rock inspection (if Rock image provided)

Invoke skill: `inspect-rock`  
Capture PebblePlan YAML output.  
If exit 2 (no Pebble layers): note fallback in output, use generic probe defaults.

### Step 2 — Generate chart

Invoke skill: `helm-toolkit` (helm-generator)  
Read the remote SKILL.md and follow its generation workflow.  
Apply Canonical overrides from `AGENTS.md`:
- Add `image.digest` field to `values.yaml`
- Wire deployment template with digest override pattern
- If PebblePlan is available, derive probes from Pebble checks instead of generic defaults

### Step 3 — Validate chart

Invoke skill: `helm-toolkit` (helm-validator)  
Read the remote SKILL.md and follow its validation workflow (lint, template render, schema validation, security checks).  
On failure: read the error, fix the specific issue in the generated templates, retry (max 3).

### Step 4 — Generate documentation

Invoke skill: `generate-documentation` with `CHART_DIR=charts/<chart-name>`  
Write `charts/<chart-name>/README.md`

### Step 5 — Commit

Commit all generated files to the working branch with message:  
`feat(<chart-name>): generate minimal Helm chart [zero-to-one]`

## Success criteria

- [ ] `charts/<chart-name>/` contains all required files (including `templates/tests/test-connection.yaml`)
- [ ] `helm-validator` passes all stages (lint, schema, security, dry-run if cluster available)
- [ ] `charts/<chart-name>/README.md` documents 100% of values
- [ ] `image.digest` field present in `values.yaml`
