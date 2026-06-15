---
name: ubuntu-helm-creator
description: Generate Kubernetes Helm charts backed by Canonical Ubuntu OCI images (rocks). Use when creating a new Helm chart from scratch for a rock; achieving feature parity with an upstream chart (Bitnami, ArtifactHub, GitHub); adding features to an existing chart. Trigger phrases are "generate helm chart", "create helm chart based on upstream chart", "helm chart for app", "feature parity with upstream", "add feature to chart", "scaffold chart", "ubuntu rock helm", "rock-backed chart". Produces chart scaffolding, values.yaml with image.digest, PSS-Restricted security defaults, Pebble-wired probes, tests, and README.md.
argument-hint: '<chart-name> [[<host>/]<repo>/<name>:<tag>] [<reference-chart>]'
---


# Ubuntu Helm Creator

Generate Kubernetes Helm charts backed by Canonical Ubuntu OCI images (rocks).

## Modes

| Mode                    | Trigger               | Example                                                                                                                                                                                                                                                      |
| ----------------------- | --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Zero-to-One**         | New chart from a rock | "Generate a Helm chart for `ubuntu/nginx:1.28-26.04_stable`"                                                                                                                                                                                                 |
| **Feature Development** | Add features chart    | "Add missing features from https://artifacthub.io/packages/helm/bitnami/nginx into the Nginx chart" or "Add env var FOO to chart Nginx" or "Create a chart for `ubuntu/nginx:1.28-26.04_stable` based on https://artifacthub.io/packages/helm/bitnami/nginx" |

---

## Prerequisites

 - The `helm-generator` skill (from https://github.com/pantheon-org/tekhne/tree/main/skills/ci-cd/helm/generator) must be installed. If missing: `npx tessl i pantheon-ai/helm-toolkit@0.1.0 --skill helm-generator`
 - Make a tool check by running `scripts/setup.sh`. If any tools are missing, they can be installed by running `scripts/setup.sh --install`. 

---

## Instructions

### Step 0 — Determine mode

```
chart already exists?
├── YES → Feature Development Mode → follow "Feature Development"
└── NO  → reference chart provided?
          ├── YES → Feature Development Mode → follow "Zero-to-One", then "Feature Development"
          └── NO  → Zero-to-One Mode → follow "Zero-to-One"
```

### Zero-to-One — Build a new chart from scratch

#### 1. Resolve the rock image

Rock image format: `[<host>/]<repo>/<name>:<tag>`
- `<host>` defaults to `docker.io`; `<repo>` defaults to `ubuntu`

 - Confirm the image exists with `scripts/inspect-rock.sh inspect [<host>/]<repo>/<name>:<tag>`
 - Get the rock's OCI entrypoint with `scripts/inspect-rock.sh entrypoint [<host>/]<repo>/<name>:<tag>`
 - Get the rock's metadata, including the OCI annotation for its description, with `scripts/inspect-rock.sh metadata [<host>/]<repo>/<name>:<tag>`
 - Inspect the rock's filesystem layout with `scripts/inspect-rock.sh filesystem [<host>/]<repo>/<name>:<tag>`


#### 2. Understand the rock's runtime

**If the entrypoint is `pebble` (most common):**

Read the Pebble documentation to understand runtime behavior:
- Overview: `https://raw.githubusercontent.com/canonical/pebble/refs/heads/master/docs/index.md`
- CLI commands (including `pebble enter`): `https://raw.githubusercontent.com/canonical/pebble/refs/heads/master/docs/reference/cli-commands.md`
- Layer specification: `https://raw.githubusercontent.com/canonical/pebble/refs/heads/master/docs/reference/layer-specification.md`

Obtain the Pebble plan (services, commands, checks) from the running image:
```bash
# If OCI ENTRYPOINT is "pebble enter":
docker run --rm <repo>/<name>:<tag> plan
# If OCI ENTRYPOINT has "--args":
docker run --rm <repo>/<name>:<tag> \; plan
```

Use the plan to derive:
- Services → Deployment container args / command
- Checks → Kubernetes liveness/readiness probes (see [Pebble-wired probes](#pebble-wired-probes))


#### 3. Generate the chart

Invoke the `helm-generator` skill from `pantheon-ai/helm-toolkit`. Follow its intructions and then apply the **Canonical overrides** below.

##### Canonical overrides (authoritative)

When generating a chart, always apply the toolkit's generation workflow first, then layer on these Canonical overrides.

**`values.yaml` — required `image` block:**
```yaml
image:
  repository: [<host>/]<repo>/<name>    # full path, no tag
  tag: "<channel-track>"                # mutable tag
  digest: ""                            # sha256 pin; empty = unpinned
  pullPolicy: IfNotPresent
```

The `image.digest` value should be set. This value can be retrieved by running `scripts/inspect-rock.sh digest <repo>/<name>:<tag>`.

**Deployment image reference (digest wiring):**
```yaml
image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}{{- if .Values.image.digest }}@{{ .Values.image.digest }}{{- end }}"
```

**`Chart.yaml` fields:**
```yaml
description: "Helm chart for <chart-name> backed by the Ubuntu rock `<rock-name>`.\n\n<rock-description>"
home: https://ubuntu.com/containers
```
Where `<rock-description>` comes from:
```bash
scripts/inspect-rock.sh metadata <repo>/<name>:<tag> | jq '."org.opencontainers.image.description"'
```

**Keep Pebble state in memory:**

Ensure every container deployment has the environment variable `PEBBLE_PERSIST` set to `never`. Otherwise the PSS security context below won't be able to apply `readOnlyRootFilesystem: true`. 

**Security context (PSS-Restricted — all Deployment/StatefulSet templates):**

Always strive for:

```yaml
securityContext:
  runAsNonRoot: true
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop: [ALL]
  seccompProfile:
    type: RuntimeDefault
```

If needing to adjust the security context after validating the chart, then justify any deviation from the above with an inline comment (e.g., if a rock is using `root` as the default OCI user and cannot be run as nonroot, then you can make an exception and allow `runAsNonRoot: false`).

##### Pebble-wired probes

When Pebble checks exist in the plan, map them to Kubernetes probes.
When no checks are defined, use generic Pebble health defaults:
```yaml
livenessProbe:
  exec:
    command: [/bin/pebble, health]
  initialDelaySeconds: 30
  periodSeconds: 10
readinessProbe:
  exec:
    command: [/bin/pebble, health]
  initialDelaySeconds: 5
  periodSeconds: 5
```

##### `LICENSE` file

**IF** requested, add a `LICENSE` file in the `<chart-path>`.

#### 4. Add tests

 - If not yet present, generate `<chart-path>/templates/tests/test-connection.yaml` with a simple test that verifies the container is running and responding to Pebble checks
 - Add a `<chart-path>/task.yaml` file. This is a Spread task definition (see https://github.com/canonical/spread), and should look like this:
  
    ```yaml
    summary: Spread tests for the <chart-name> Helm chart

    environment:
      HELM_RELEASE: test-<chart-name>
      HELM_REGISTRY: '$(HOST: echo "${HELM_REGISTRY:-}")'
      HELM_REGISTRY_USERNAME: '$(HOST: echo "${HELM_REGISTRY_USERNAME:-}")'
      HELM_REGISTRY_PASSWORD: '$(HOST: echo "${HELM_REGISTRY_PASSWORD:-}")'

    execute: |
      # Common file from $PROJECT_ROOT/spread/lib/
      helm-test

      # <OPTIONAL ADDITIONAL TESTS>

    restore: |
      helm uninstall "$HELM_RELEASE" --wait || true
    ```

 - If, and ONLY IF requested by the user, add a `<chart-path>/policy.rego` file with OPA policies that are specific for the chart
 - Add a `<chart-path>/tests/` directory with YAML test files for Helm unittest (see https://github.com/helm-unittest/helm-unittest)

#### 5. Validate


Invoke skill: [ubuntu-helm-validator](../ubuntu-helm-validator).

→ On failure: apply the [Failure and Retry Protocol](#failure-and-retry-protocol) (max 5 attempts).


#### 6. Document

Invoke skill: [ubuntu-helm-docs](../ubuntu-helm-docs) with `CHART_DIR=<chart-path>`

---


### Feature Development — Add features to an existing chart


**Pre-condition**: chart already scaffolded (via "Zero-to-One" mode, or is pre-existing).

#### 1. Analyse the existing target chart

Invoke skill: [ubuntu-helm-analyzer](../ubuntu-helm-analyzer) with the existing chart path.

#### 2. Collect the new features

**IF** a reference chart is provided: the goal is to reach parity with the upstream chart. Invoke skill: [ubuntu-helm-analyzer](../ubuntu-helm-analyzer) with the reference chart URL/path. Skip features marked `deprecated` (prompt user if in doubt).

#### 3. Inject features one by one

For each applicable feature in order:

1. **Read** the feature's source template(s) from the reference chart
2. **Adapt** them to the working chart's conventions:
   - Replace hardcoded names with `{{ include "<chart>.fullname" . }}` references
   - Replace hardcoded labels with `{{ include "<chart>.labels" . | nindent N }}`
   - Ensure all values are exposed in `values.yaml` with sensible defaults
   - Apply PSS-Restricted security context if the feature adds a container
3. **Write** the adapted template(s) to the working chart's `templates/` directory
4. **Update** `values.yaml` — add new keys for this feature, with defaults that keep the feature disabled by default (e.g., `ingress.enabled: false`)
5. **Update** `values.schema.json` **ONLY** if it exists already, adding the JSON Schema entries for the new values keys
6. **Do NOT modify** `Chart.yaml`, `_helpers.tpl` (unless adding new named template needed for this feature), or any existing template that was already passing tests
7. **Update** the chart's tests. Add or modify `<chart-path>/templates/tests/test-connection.yaml`, `<chart-path>/task.yaml`, `<chart-path>/policy.rego`, and/or `<chart-path>/tests/` files as needed to cover the new feature
8. **Validate** the updated chart by invoking the skill [ubuntu-helm-validator](../ubuntu-helm-validator)
9. **On failure** apply [Failure and Retry Protocol](#failure-and-retry-protocol) (max 5 attempts per feature)
   - If still failing after 5 attempts:
     - Roll back all changes for this feature
     - Record failure reason for the final report
     - Continue to next feature
10. **On success**:
    - **Update the README** of the updated chart by invoking the skill [ubuntu-helm-docs](../ubuntu-helm-docs) with `CHART_DIR=<chart-path>`

---

## Final Report

Produce after any workflow completes. Deliver as a chat message (interactive) or PR comment.

```markdown
## Helm Chart Generation Report

**Rock image**: docker.io/<repo>/<name>:<tag>
**Reference chart**: <name> v<version> — <url> (if applicable)

### Feature Summary

| Feature        | Status              | Notes       |
| -------------- | ------------------- | ----------- |
| `<feature-id>` | succeeded / dropped | Drop reason |

**Totals**: Succeeded: N | Dropped: M | Total: N+M

### Dropped Feature Details
<for each dropped feature: final error + what was tried>
```

---

## Success Criteria

- [ ] `<chart-path>/` contains all required files, including `templates/tests/test-connection.yaml`, `tests/` and `task.yaml`
- [ ] `helm-validator` passes all stages (lint, schema, security, dry-run)
- [ ] `<chart-path>/README.md` documents 100% of values
- [ ] `image.digest` present in `values.yaml`
- [ ] `image:` template uses digest-override wiring
- [ ] All Deployment/StatefulSet containers carry PSS-Restricted `securityContext`

---

## Failure and Retry Protocol

On any skill failure (lint error, test failure, non-zero exit):

1. Read the **full** error output — do not guess the root cause
2. Identify the **specific** failing line or check
3. Apply a **targeted** fix to the chart or template
4. Retry the failing skill
5. If the identical error recurs, try a **different approach** — do not repeat the same fix
