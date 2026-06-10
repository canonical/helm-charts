---
name: ubuntu-helm-analyzer
description: >-
  Obtain and analyze a Helm chart (local path, ArtifactHub URL, Helm repo reference, or Git URL) and extract an ordered list of discrete features as YAML.
  Use when: analyzing an upstream chart before feature parity, comparing charts, listing features in a reference chart, understanding chart structure.
  Trigger phrases: "analyze chart", "list features in chart", "compare chart features", "what features does this chart have".
argument-hint: '<chart-ref> (local path, ArtifactHub URL, helm repo ref, or Git URL)'
---

# Ubuntu Helm Analyzer

Analyze a Helm chart and extract an ordered list of discrete, injectable features as YAML output.

## Input

The chart reference can be any of:

| Format | Example |
|--------|---------|
| Local path | `charts/rabbitmq/` |
| ArtifactHub URL | `https://artifacthub.io/packages/helm/bitnami/nginx` |
| Helm repo reference | `bitnami/nginx` |
| Git URL | `https://github.com/bitnami/charts/tree/main/bitnami/nginx` |

## Workflow

### Step 0 — Obtain the chart locally

If the input **is not** a local directory, fetch it first into a temporary location (e.g. `/tmp/reference-charts/`):

**ArtifactHub URL:**
```bash
helm repo add <repo-name> <repo-url>
helm repo update
helm pull <repo-name>/<chart-name> --untar --untardir /tmp/reference-charts
```

**Helm repo reference** (e.g. `bitnami/nginx`):
```bash
helm pull <repo>/<chart> --untar --untardir /tmp/reference-charts
```

**Git URL** (e.g. `https://github.com/<org>/<repo>/tree/<branch>/<path>`):
```bash
git clone --depth 1 --branch <branch> --filter=blob:none --sparse \
  https://github.com/<org>/<repo>.git /tmp/reference-charts/<repo>
cd /tmp/reference-charts/<repo>
git sparse-checkout set <path>
# This also works for GitLab, Gitea, and other forges — adjust the URL parsing accordingly
```

If the input **is** a local directory, then use as-is.

### Step 1 — Enumerate templates

List every file under `<chart>/templates/` (excluding `_helpers.tpl`, `NOTES.txt`, and `tests/`).

For each file, extract:
- Kubernetes `kind:`(s)
- `apiVersion:`(s)
- All `.Values.*` references (these become the feature's `values_keys`)

### Step 2 — Classify as base or feature

**Base chart** (not features — produced by the generator):
- `Deployment` or `StatefulSet` (primary workload)
- `Service` (primary service)
- `ServiceAccount`

Everything else is a **feature**.

**Grouping rules:**
- Related templates serving the same capability → single feature (e.g. `Role` + `RoleBinding` → `rbac`)
- Conditionally-rendered Kinds in a single template → separate features unless they always appear together
- Embedded capabilities in the workload template (initContainers, extra volumes, sidecars, extra env) → each is a separate feature

### Step 3 — Extract values keys

For every feature, collect all `.Values.*` dotted paths from its source templates. Deduplicate and sort alphabetically.

### Step 4 — Detect deprecated APIs

Flag features with deprecated/removed `apiVersion` for Kubernetes 1.29+:
- `extensions/v1beta1`
- `networking.k8s.io/v1beta1`
- `policy/v1beta1` (PodSecurityPolicy)
- `rbac.authorization.k8s.io/v1beta1`

Mark these as `deprecated_api: true`.

If a feature ends up being marked as `deprecated_api: false`, run an additional check to verify the chart's `Chart.yaml` and README files for any mentions of deprecated APIs in the documentation, and if found, mark as `deprecated_api: true` with a warning that the chart may be using deprecated APIs despite not declaring them in the templates. 

### Step 5 — Assign priority

Assign numeric `priority` (1 = inject first):

1. Independent data resources (ConfigMap, Secret)
2. RBAC (Role, RoleBinding, ServiceAccount extras)
3. Networking (Ingress, NetworkPolicy)
4. Scaling & availability (HPA, PDB, VPA)
5. Monitoring & observability (ServiceMonitor, PrometheusRule)
6. Workload modifications (initContainers, sidecars, extra volumes/env)
7. Stateful resources (PVC, Jobs, CronJobs)
8. Everything else (custom CRDs, misc)
9. Deprecated API features → always last

Within the same category, simpler features (fewer templates, fewer values keys) come first.

## Output

A YAML document sorted by `priority` ascending:

```yaml
features:
  - id: <kebab-case-id>
    name: <human-readable name>
    kind: <primary Kubernetes Kind>
    api_version: <apiVersion>
    source_templates:
      - templates/<file>.yaml
    values_keys:
      - <dotted.path.to.value>
    priority: <number>
    deprecated_api: false
```

## Rules

- Discover features dynamically — do NOT use a hardcoded list
- Include unknown Kinds and CRDs with their `kind` and `api_version` as-is
- Features with no `.Values` references → `values_keys: []`
- Output must be valid, parseable YAML
