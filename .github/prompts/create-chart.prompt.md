---
mode: agent
description: "Generate a Helm chart for a Canonical Rock-backed application"
---

# Create Chart

Follow all rules defined in the root `AGENTS.md` file.

## Inputs

- **Application name**: `${{ input:name | What is the application name? }}`
- **Rock image** (optional): `${{ input:image | Rock image reference (e.g. docker.io/ubuntu/app:1.0 or ghcr.io/org/app:latest), or leave empty }}`
- **Reference chart** (optional): `${{ input:reference | Path or URL to a reference chart to achieve feature parity with (e.g. charts/upstream-app or https://github.com/org/repo/tree/main/charts/app), or leave empty }}`

## Instructions

Generate a Helm chart at `charts/{{ name }}/`.

**Choose the workflow based on the inputs:**

### If no reference chart was provided → Zero-to-One Mode

Follow the **Zero-to-One Mode** workflow from `AGENTS.md`:

1. If a Rock image was provided, run `inspect-rock` to extract the Pebble plan
2. Use the `helm-toolkit` skill (helm-generator) to scaffold the chart — read `skills/helm-toolkit.md` for the remote SKILL.md URLs, fetch and follow them
3. Apply all Canonical overrides from `AGENTS.md` (image.digest field, deployment digest wiring, PSS-Restricted security defaults)
4. Use the `helm-toolkit` skill (helm-validator) to validate the chart — fetch and follow the remote validator SKILL.md
5. On validation failure: diagnose, fix, retry (max 3)
6. Run `generate-documentation` to produce `charts/{{ name }}/README.md`

### If a reference chart was provided → Feature Parity Mode

Follow the **Feature Parity Mode** workflow from `AGENTS.md`:

1. If the reference is a URL, fetch it first. If it is a local path, read it directly
2. If a Rock image was provided, run `inspect-rock` to extract the Pebble plan
3. Run `analyse-reference-chart` on the reference to extract an ordered feature list
4. Use the `helm-toolkit` skill (helm-generator) to produce the minimal base chart with Canonical overrides — do NOT copy the reference chart
5. Validate the base chart with `helm-toolkit` (helm-validator)
6. For each feature in order:
   a. Run `inject-feature` to add the feature to the chart
   b. Validate with `helm-toolkit` (helm-validator)
   c. On failure: diagnose, fix, retry (max 5 total per feature)
   d. If still failing after 5 attempts: drop the feature and record the reason
7. Run `generate-documentation` to produce `charts/{{ name }}/README.md`

## Rules

- Do NOT produce bloated charts. Every template must have a clear, required purpose.
- The output chart must NOT be a copy of the reference — always start from a minimal base.
- Apply PSS-Restricted security defaults to all containers.
