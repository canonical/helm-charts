# rabbitmq

Helm chart for rabbitmq backed by the Ubuntu rock `ubuntu/rabbitmq`.

RabbitMQ is an open source multi-protocol messaging broker.

RabbitMQ is a reliable and mature messaging and streaming broker, which is
easy to deploy on cloud environments, on-premises, and on your local machine.
It is currently used by millions worldwide. This is a chiselled RabbitMQ
image.

## Architecture

This chart deploys the following Kubernetes resources:

- **Deployment** — runs the RabbitMQ server container using Pebble as the entrypoint
- **Service** — exposes the AMQP port (5672) within the cluster
- **ServiceAccount** — dedicated service account for the RabbitMQ pods

The container uses TCP socket probes against the AMQP port (5672) for liveness and readiness to ensure the broker actually started. A PSS-Restricted security context is applied; however `readOnlyRootFilesystem` is disabled by default because the current rock writes to the image filesystem at runtime (see `values.yaml`).

## Prerequisites

- Kubernetes 1.29+
- Helm 3+

## Installation

```bash
helm install my-rabbitmq charts/rabbitmq/
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `image.repository` | `string` | `docker.io/ubuntu/rabbitmq` | Container image repository |
| `image.tag` | `string` | `4.0-26.04_stable` | Image tag (mutable channel track) |
| `image.digest` | `string` | `sha256:9d6a3268002b91e2c93a86726f281539cdd089a07d5fa681e506aad66b4e70d1` | Image digest for pinning (sha256:...). Leave empty to use tag only |
| `image.pullPolicy` | `string` | `IfNotPresent` | Image pull policy |
| `replicaCount` | `integer` | `1` | Number of replicas |
| `nameOverride` | `string` | `""` | Override the chart name |
| `fullnameOverride` | `string` | `""` | Override the full resource name |
| `serviceAccount.create` | `boolean` | `true` | Whether to create a ServiceAccount |
| `serviceAccount.annotations` | `object` | `{}` | Annotations to add to the ServiceAccount |
| `serviceAccount.name` | `string` | `""` | Override the ServiceAccount name |
| `podAnnotations` | `object` | `{}` | Annotations to add to the Pod |
| `podSecurityContext` | `object` | `{}` | Security context for the Pod |
| `securityContext.runAsNonRoot` | `boolean` | `true` | Require running as a non-root user |
| `securityContext.allowPrivilegeEscalation` | `boolean` | `false` | Prevent privilege escalation |
| `securityContext.readOnlyRootFilesystem` | `boolean` | `false` | Mount root filesystem as read-only |
| `securityContext.capabilities.drop` | `list` | `[ALL]` | Linux capabilities to drop |
| `securityContext.seccompProfile.type` | `string` | `RuntimeDefault` | Seccomp profile type |
| `service.type` | `string` | `ClusterIP` | Service type |
| `service.port` | `integer` | `5672` | Service port for AMQP connections |
| `resources.limits.cpu` | `string` | `500m` | CPU resource limit |
| `resources.limits.memory` | `string` | `512Mi` | Memory resource limit |
| `resources.requests.cpu` | `string` | `100m` | CPU resource request |
| `resources.requests.memory` | `string` | `128Mi` | Memory resource request |
| `nodeSelector` | `object` | `{}` | Node selector for Pod scheduling |
| `tolerations` | `list` | `[]` | Tolerations for Pod scheduling |
| `affinity` | `object` | `{}` | Affinity rules for Pod scheduling |
| `livenessProbe.tcpSocket.port` | `string` | `amqp` | Liveness probe target port (AMQP) |
| `livenessProbe.initialDelaySeconds` | `integer` | `30` | Liveness probe initial delay in seconds |
| `livenessProbe.periodSeconds` | `integer` | `10` | Liveness probe period in seconds |
| `readinessProbe.tcpSocket.port` | `string` | `amqp` | Readiness probe target port (AMQP) |
| `readinessProbe.initialDelaySeconds` | `integer` | `5` | Readiness probe initial delay in seconds |
| `readinessProbe.periodSeconds` | `integer` | `5` | Readiness probe period in seconds |

## Upgrading

```bash
helm upgrade my-rabbitmq charts/rabbitmq/
```
