# global policy
package main

import rego.v1

workload_kinds := {"Deployment", "StatefulSet", "DaemonSet"}

# Deny workloads without resource limits
deny contains msg if {
  workload_kinds[input.kind]
  container := input.spec.template.spec.containers[_]
  not container.resources.limits
  msg := sprintf("Container %s in %s %s must have resource limits", [container.name, input.kind, input.metadata.name])
}

# Require app.kubernetes.io/name label
deny contains msg if {
  workload_kinds[input.kind]
  not input.metadata.labels["app.kubernetes.io/name"]
  msg := sprintf("%s %s must have app.kubernetes.io/name label", [input.kind, input.metadata.name])
}

# Deny :latest tag
deny contains msg if {
  workload_kinds[input.kind]
  container := input.spec.template.spec.containers[_]
  endswith(container.image, ":latest")
  msg := sprintf("Container %s in %s %s uses :latest tag which is not allowed", [container.name, input.kind, input.metadata.name])
}

# Require readiness probe
warn contains msg if {
  workload_kinds[input.kind]
  container := input.spec.template.spec.containers[_]
  not container.readinessProbe
  msg := sprintf("Container %s in %s %s should have a readiness probe", [container.name, input.kind, input.metadata.name])
}
