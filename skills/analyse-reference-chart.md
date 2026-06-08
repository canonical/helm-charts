# Skill: analyse-reference-chart

**Purpose**: Obtain and analyse an existing Helm chart — local or upstream — and dynamically extract an ordered list of **every** discrete feature that can be independently injected into a new chart

## Input

- Reference chart: **one** of the following
  - A local directory path (e.g. `charts/reference-chart/`)
  - An ArtifactHub URL (e.g. `https://artifacthub.io/packages/helm/bitnami/nginx`)
  - A Helm repository reference (e.g. `bitnami/nginx`)
  - A VCS URL pointing to the chart directory (e.g. `https://github.com/bitnami/charts/tree/main/bitnami/nginx`)

## Step 0 — Obtain the chart locally

If the input is **not** a local directory, fetch it first:

1. **ArtifactHub URL**: extract the repository and chart name from the URL, then:
   ```bash
   # Add the repo (derive repo URL from ArtifactHub page or use the ArtifactHub API)
   helm repo add <repo-name> <repo-url>
   helm repo update
   # Pull and untar into a temp directory
   helm pull <repo-name>/<chart-name> --untar --untardir /tmp/reference-charts
   ```
   The local path is now `/tmp/reference-charts/<chart-name>/`

2. **Helm repo reference** (e.g. `bitnami/nginx`): assume the repo is already added, then:
   ```bash
   helm pull <repo>/<chart> --untar --untardir /tmp/reference-charts
   ```

3. **VCS URL** (e.g. `https://github.com/bitnami/charts/tree/main/bitnami/nginx`): clone only the chart directory using a sparse checkout:
   ```bash
   # Parse the URL to extract: host, org, repo, branch, and path
   # For GitHub: https://github.com/<org>/<repo>/tree/<branch>/<path>
   git clone --depth 1 --branch <branch> --filter=blob:none --sparse \
     https://github.com/<org>/<repo>.git /tmp/reference-charts/<repo>
   cd /tmp/reference-charts/<repo>
   git sparse-checkout set <path>
   ```
   The local path is now `/tmp/reference-charts/<repo>/<path>/`

   This also works for GitLab, Gitea, and other forges — adjust the URL parsing accordingly

4. **Local directory**: use as-is

After this step, all subsequent analysis operates on the local directory

## Procedure

### 1 — Enumerate templates

List every file under `<chart>/templates/` (excluding `_helpers.tpl`, `NOTES.txt`, and `tests/`).
For each file, read it and extract:

- The Kubernetes **Kind**(s) it defines (look for `kind:` lines)
- The **apiVersion**(s) it uses
- All `.Values.*` references → these become the feature's `values_keys`

### 2 — Classify as base or feature

The **base chart** consists of only these resources (they are produced by the helm-generator and are NOT features):

- `Deployment` or `StatefulSet` (the primary workload)
- `Service` (the primary service)
- `ServiceAccount`

Everything else is a **feature**. Each distinct Kind (or logical group of related Kinds) becomes one feature entry.

#### Grouping rules

- Multiple templates that serve the same logical capability should be **grouped into a single feature** (e.g. `Role` + `RoleBinding` + `ClusterRole` → feature `rbac`; `Certificate` + `Issuer` → feature `tls-certificates`)
- If a single template produces multiple Kinds via `{{- if }}` blocks, each conditionally-rendered Kind is a separate feature unless they always appear together
- Embedded capabilities inside the base workload template (e.g. `initContainers`, extra `volumes`/`volumeMounts`, sidecar containers, extra `env`/`envFrom`) are each a separate feature even though they live in `deployment.yaml`

### 3 — Extract values keys

For every feature, collect the full dotted paths of all `.Values.*` references from its source templates. Deduplicate and sort alphabetically.

### 4 — Detect deprecated APIs

Flag any feature whose `apiVersion` is deprecated or removed in Kubernetes 1.29+ with `deprecated_api: true`. Common deprecated APIs:

- `extensions/v1beta1`
- `networking.k8s.io/v1beta1`
- `policy/v1beta1` (PodSecurityPolicy)
- `rbac.authorization.k8s.io/v1beta1`


### 5 — Assign priority and order

Assign a numeric `priority` (1 = inject first) using these rules, in order:

1. **Independent data resources** (ConfigMap, Secret) → lowest priority numbers
2. **RBAC resources** (Role, RoleBinding, ServiceAccount extras) → next
3. **Networking** (Ingress, NetworkPolicy) → next
4. **Scaling & availability** (HPA, PDB, VPA) → next
5. **Monitoring & observability** (ServiceMonitor, PrometheusRule, PodMonitor) → next
6. **Workload modifications** (initContainers, sidecars, extra volumes, extra env) → next
7. **Stateful resources** (PVC, StatefulSet extras, Jobs, CronJobs) → next
8. **Everything else** (custom CRDs, misc) → next
9. **Deprecated API features** → always last (highest priority number)

Within the same category, simpler features (fewer templates, fewer values keys) come first.

## Output format

Output a YAML document:

```yaml
features:
  - id: <kebab-case-id>
    name: <human-readable name>
    kind: <primary Kubernetes Kind>
    api_version: <apiVersion used>
    source_templates:
      - templates/<file>.yaml
    values_keys:
      - <dotted.path.to.value>
    priority: <number>
    deprecated_api: false   # or true

  # ... one entry per discovered feature, sorted by priority ascending
```

## Rules

- Do NOT hardcode a fixed list of features — discover them from whatever is in the chart
- Do NOT skip unknown Kinds or CRDs — include them with `kind` and `api_version` as-is
- If a template contains no `.Values` references, set `values_keys: []`
- The output must be valid YAML, parseable by any YAML loader
