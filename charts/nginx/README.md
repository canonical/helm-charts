# nginx

A Helm chart for nginx backed by the Canonical Ubuntu nginx rock (ubuntu/nginx).

## Architecture

This chart deploys the following Kubernetes resources:

- **Deployment** — runs the nginx web server using the `ubuntu/nginx` Canonical rock image. The container runs as a non-root user with a fully PSS-Restricted security context (`readOnlyRootFilesystem`, `allowPrivilegeEscalation: false`, `capabilities.drop: ALL`, `seccompProfile: RuntimeDefault`).
- **Service** — ClusterIP service exposing nginx on port 80.
- **ServiceAccount** — dedicated service account for the nginx pods.

HTTP liveness and readiness probes are configured against `GET /` on port 80, as no Pebble plan was available at chart generation time (no container runtime in the build environment). These can be adjusted if the rock exposes dedicated health endpoints.

The `image.digest` field in `values.yaml` provides optional digest pinning. When set to a `sha256:...` value, the deployment references the image by digest, guaranteeing an exact layer regardless of tag mutability.

## Prerequisites

- Kubernetes 1.29+
- Helm 3.x

## Installation

```bash
helm install nginx charts/nginx/
```

To pin to a specific image digest:

```bash
helm install nginx charts/nginx/ \
  --set image.digest=sha256:<digest>
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `replicaCount` | `integer` | `1` | Number of nginx pod replicas |
| `image.repository` | `str` | `docker.io/ubuntu/nginx` | Container image repository (full registry path, no tag) |
| `image.tag` | `str` | `1.28-26.04_edge` | Mutable image tag (channel track); overrides the chart appVersion |
| `image.digest` | `str` | `""` | sha256 digest pin; when non-empty, takes precedence over `image.tag` |
| `image.pullPolicy` | `str` | `IfNotPresent` | Kubernetes image pull policy |
| `nameOverride` | `str` | `""` | Override for the chart name component of resource names |
| `fullnameOverride` | `str` | `""` | Full override for resource names |
| `serviceAccount.create` | `bool` | `true` | Whether to create a dedicated ServiceAccount |
| `serviceAccount.automount` | `bool` | `true` | Whether to automount the ServiceAccount API token |
| `serviceAccount.name` | `str` | `""` | Name of an existing ServiceAccount to use (generated when empty and `create: true`) |
| `podSecurityContext.runAsNonRoot` | `bool` | `true` | Reject pods that run as root at the pod level |
| `podSecurityContext.runAsUser` | `integer` | `1000` | UID to run the pod as |
| `podSecurityContext.fsGroup` | `integer` | `1000` | GID for volume ownership |
| `securityContext.runAsNonRoot` | `bool` | `true` | Reject containers that run as root |
| `securityContext.allowPrivilegeEscalation` | `bool` | `false` | Disallow privilege escalation (PSS-Restricted) |
| `securityContext.readOnlyRootFilesystem` | `bool` | `true` | Mount the container root filesystem as read-only |
| `securityContext.capabilities.drop[0]` | `str` | `ALL` | Drop all Linux capabilities from the container |
| `securityContext.seccompProfile.type` | `str` | `RuntimeDefault` | Seccomp profile type (PSS-Restricted requires RuntimeDefault or Localhost) |
| `service.type` | `str` | `ClusterIP` | Kubernetes Service type |
| `service.port` | `integer` | `80` | Port exposed by the Service |
| `service.targetPort` | `integer` | `80` | Port the container listens on |
| `service.portName` | `str` | `http` | Port name used in Service and container port definitions |
| `livenessProbe.httpGet.path` | `str` | `/` | HTTP path for the liveness health check |
| `livenessProbe.httpGet.port` | `str` | `http` | Named port for the liveness probe |
| `livenessProbe.initialDelaySeconds` | `integer` | `30` | Seconds before the first liveness probe fires |
| `livenessProbe.periodSeconds` | `integer` | `10` | Interval between liveness probe checks |
| `readinessProbe.httpGet.path` | `str` | `/` | HTTP path for the readiness health check |
| `readinessProbe.httpGet.port` | `str` | `http` | Named port for the readiness probe |
| `readinessProbe.initialDelaySeconds` | `integer` | `5` | Seconds before the first readiness probe fires |
| `readinessProbe.periodSeconds` | `integer` | `5` | Interval between readiness probe checks |
| `ingress.enabled` | `bool` | `false` | Enable an Ingress resource |
| `ingress.className` | `str` | `""` | Ingress class name (e.g. `nginx`) |
| `ingress.hosts[0].host` | `str` | `nginx.local` | Hostname for the default Ingress rule |
| `ingress.hosts[0].paths[0].path` | `str` | `/` | URL path prefix for the default Ingress rule |
| `ingress.hosts[0].paths[0].pathType` | `str` | `ImplementationSpecific` | Ingress path type |
| `resources.limits.cpu` | `str` | `100m` | CPU limit for the nginx container |
| `resources.limits.memory` | `str` | `128Mi` | Memory limit for the nginx container |
| `resources.requests.cpu` | `str` | `100m` | CPU request for the nginx container |
| `resources.requests.memory` | `str` | `128Mi` | Memory request for the nginx container |
| `autoscaling.enabled` | `bool` | `false` | Enable a HorizontalPodAutoscaler |
| `autoscaling.minReplicas` | `integer` | `1` | Minimum replica count when autoscaling is enabled |
| `autoscaling.maxReplicas` | `integer` | `100` | Maximum replica count when autoscaling is enabled |
| `autoscaling.targetCPUUtilizationPercentage` | `integer` | `80` | Target CPU utilisation percentage for autoscaling |

## Upgrading

```bash
helm upgrade nginx charts/nginx/
```
