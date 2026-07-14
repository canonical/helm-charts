# AGENTS.md

> [!WARNING]
> To create or modify anything under `charts/`, adopt the
> Helm Crafter persona at [`.agents/agents/helm-crafter/agent.md`](.agents/agents/helm-crafter/agent.md).

## What this repo is

A collection of [Helm charts](https://helm.sh/) for applications backed by
[Ubuntu rocks](https://ubuntu.com/containers/docs) (Canonical Ubuntu-based OCI
images). Charts landing on the default branch are versioned, packaged, and
published to GHCR.

## Repository layout

Not exhaustive -- only the paths relevant to chart work, each with what is
not obvious from its name.

- `charts/<name>/` -- one directory per chart, where `<name>` is user-defined or
  derived from the rock name.
- `.agents/skills/` -- [Agent Skills](https://agentskills.io/specification) for chart work.
- `.agents/agents/` -- sub-agent personas (see the
  [Helm Crafter Agent](.agents/agents/helm-crafter/agent.md)).
- `policy.rego` -- global OPA/conftest policy applied to rendered manifests.
- `spread.yaml`, `spread/` -- integration-test harness
  ([spread](https://github.com/canonical/spread) + LXD).
- `.github/workflows/` -- CI and chart publishing to GHCR.

## Conventions

- **Commits** follow [Conventional Commits](https://www.conventionalcommits.org/).
- **PRs** stay small and focused -- avoid bundling multiple charts or features.
  See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for full PR etiquette and the CLA.
