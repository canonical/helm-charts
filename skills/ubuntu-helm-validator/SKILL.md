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

Invoke the `helm-validator` skill from `pantheon-ai/helm-toolkit`, against the provided chart `<chart-path>`. Follow its entire pipeline.
