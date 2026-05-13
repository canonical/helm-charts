# Skill: analyse-reference-chart

**Purpose**: Read an existing Helm chart directory and extract an ordered list of discrete features that can be independently injected into a new chart.

## When to invoke

Step 3 of the Feature Parity workflow, before generating the base chart.

## Input

- Reference chart directory path (e.g., `charts/reference-chart/`)

## What to look for

A **feature** is a discrete Kubernetes resource type or logical capability present in the reference chart that is NOT part of the minimal base chart. Examples:

| Feature ID | What to look for | Source template |
|---|---|---|
| `ingress` | `templates/ingress.yaml` | `templates/ingress.yaml` |
| `hpa` | `templates/hpa.yaml` or `HorizontalPodAutoscaler` | `templates/hpa.yaml` |
| `pdb` | `templates/pdb.yaml` or `PodDisruptionBudget` | `templates/pdb.yaml` |
| `rbac` | `templates/rbac.yaml`, `ClusterRole`, `RoleBinding` | `templates/rbac.yaml` |
| `configmap` | `templates/configmap.yaml` | `templates/configmap.yaml` |
| `secrets` | `templates/secret.yaml` | `templates/secret.yaml` |
| `network-policy` | `templates/networkpolicy.yaml` | `templates/networkpolicy.yaml` |
| `custom-env` | Extra env vars in deployment not in base | `templates/deployment.yaml` diff |
| `extra-volumes` | Extra volume mounts in deployment | `templates/deployment.yaml` diff |
| `init-containers` | `initContainers:` block in deployment | `templates/deployment.yaml` diff |

## Output format

Output a YAML document listing features in recommended injection order (simpler features first):

```yaml
features:
  - id: configmap
    name: ConfigMap
    source_templates:
      - templates/configmap.yaml
    values_keys:
      - configMap.data
    priority: 1

  - id: ingress
    name: Ingress
    source_templates:
      - templates/ingress.yaml
    values_keys:
      - ingress.enabled
      - ingress.className
      - ingress.hosts
      - ingress.tls
    priority: 2

  - id: hpa
    name: HorizontalPodAutoscaler
    source_templates:
      - templates/hpa.yaml
    values_keys:
      - autoscaling.enabled
      - autoscaling.minReplicas
      - autoscaling.maxReplicas
    priority: 3
```

## Ordering rules

1. Independent resources (ConfigMap, Secret) before resources that reference them
2. Simpler features (single template, few values) before complex ones
3. Features with Kubernetes API deprecation risk → note them with `deprecated_api: true`
4. Features using deprecated APIs should be ordered last (highest drop risk)
