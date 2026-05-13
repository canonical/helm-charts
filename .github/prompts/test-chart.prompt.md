---
mode: agent
description: "Validate an existing Helm chart (lint, schema, security, E2E)"
---

# Test Chart

Follow all rules defined in the root `AGENTS.md` file.

## Inputs

- **Chart name**: `${{ input:name | Which chart to test? (e.g. myapp) }}`

## Instructions

Validate the chart at `charts/{{ name }}/` by running the full `helm-toolkit` (helm-validator) pipeline:

1. Read `skills/helm-toolkit.md` to get the remote validator SKILL.md URL
2. Fetch and follow the remote validator SKILL.md instructions against `charts/{{ name }}/`
3. Report the structured pass/fail result for each validation stage
4. If any stage fails:
   - Read the full error output carefully
   - Identify the root cause (look at the specific error line, do not guess)
   - Apply a targeted fix to the chart or template
   - Re-run the failing validation stage
   - If the same error recurs unchanged, try a different approach
   - Max 3 retries per failure
5. After all stages pass (or retries are exhausted), print a summary:
   - Which stages passed
   - Which stages failed and why (if any)
   - Any fixes that were applied
