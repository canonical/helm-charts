---
name: ubuntu-helm-validator
description: >-
  Validate Kubernetes Helm charts backed by Canonical Ubuntu OCI images (rocks).
  Wraps the helm-validator skill.
  Use when: validating a chart, linting templates, running dry-run, checking security
  defaults, verifying chart structure.
  Trigger phrases: "validate chart", "lint chart", "check chart", "helm lint", "dry-run chart", "security check chart".
argument-hint: '<chart-path>'
---

# Ubuntu Helm Validator

Validate Helm charts against both upstream best practices (via the `helm-validator` skill) and this project's Canonical requirements.

## Prerequisites

- The `helm-validator` skill (from https://github.com/pantheon-org/tekhne/tree/main/skills/ci-cd/helm/validator) must be installed. If missing: `npx tessl i pantheon-ai/helm-toolkit@0.1.0 --skill helm-validator`
- Run `scripts/setup.sh` to verify tools are present. If any tools are missing, they can be installed by running `scripts/setup.sh --install`. 

## Instructions

 - Invoke the `helm-validator` skill from `pantheon-ai/helm-toolkit`, against the provided chart `<chart-path>`. Follow its entire pipeline
 - After the `helm-validator` skill completes, run these additional tests:
   - Lint the chart using `scripts/run-test.sh lint <chart-path>`
   - Render the chart templates using `scripts/run-test.sh render-templates <chart-path>`
   - Run OPA policy tests using `scripts/run-test.sh test-policies <chart-path>`
   - Run Helm unit tests using `scripts/run-test.sh unit-test <chart-path>`
   - If Spread is installed (check with `command -v spread`), there is a `spread.yaml` file at the root of the project, and the chart has a `task.yaml` file, then run integration tests using `scripts/run-test.sh integration-test <chart-path>`. IMPORTANT: this script needs to be called from the root of the project, where the `spread.yaml` file is located.
