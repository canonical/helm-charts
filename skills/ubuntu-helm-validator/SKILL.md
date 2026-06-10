---
name: ubuntu-helm-validator
description: >-
  Validate Kubernetes Helm charts backed by Canonical Ubuntu OCI images (rocks).
  Wraps the tekhne helm-validator with Canonical-specific checks.
  Use when: validating a chart, linting templates, running dry-run, checking security
  defaults, verifying chart structure.
  Trigger phrases: "validate chart", "lint chart", "check chart", "helm lint", "dry-run chart", "security check chart".
argument-hint: '<chart-path>'
---

# Ubuntu Helm Validator

Validate Helm charts against both upstream best practices (via the tekhne `helm-validator` skill) and this project's Canonical requirements.

## Prerequisites

- The tekhne `helm-validator` skill (from [pantheon-org/tekhne](https://github.com/pantheon-org/tekhne)) must be installed. If missing: `npx tessl i pantheon-ai/helm-toolkit@0.1.0`
- Run `scripts/setup.sh` from the `ubuntu-helm-validator` skill to verify tools are present.

## Instructions

Invoke the `helm-validator` skill from `pantheon-ai/helm-toolkit`, against the provided chart `<chart-path>`. Follow its entire pipeline:
