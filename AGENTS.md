# AGENTS.md

Guidance for AI coding agents working in the `canonical/helm-charts` repository.
This file describes the project, its layout, and how to build and test changes.
For human-facing contribution rules, see [`CONTRIBUTING.md`](./CONTRIBUTING.md).

## What this repo is

A collection of [Helm charts](https://helm.sh/) for applications backed by
[Ubuntu rocks](https://ubuntu.com/containers/docs) (Canonical Ubuntu-based OCI
images). Charts landing on the default branch are versioned, packaged, and
published to GHCR.

## Repository layout

- `charts/<name>/` -- one directory per chart. Each chart is self-contained and
  ships its own `README.md`, `Chart.yaml`, `values.yaml`, `templates/`, and
  `tests/` (helm-unittest specs).
- `.agents/skills/` -- [Agent Skills](https://agentskills.io/specification) for
  chart work, discoverable by any conforming agent (see [Skills](#skills)).
- `policy.rego` -- global OPA/conftest policy applied to rendered manifests.
- `spread.yaml`, `spread/` -- integration-test harness (spread + LXD).
- `justfile` -- task runner for all local build/test commands.
- `.pre-commit-config.yaml` -- runs `helm lint` on every chart at commit time.

## Setup

Requires [`just`](https://just.systems) (e.g. `snap install just --classic`).

```
just setup
```

This installs chart tooling (helm, validators), `pre-commit`, and the git hooks.

## Build and test

All tasks go through `just` (run `just` alone to list them). Chart names are the
directory name under `charts/`.

- `just lint <chart>` -- `helm lint`
- `just render-templates <chart>` -- render templates, optionally validate with `kubectl`
- `just test-policies <chart>` -- check rendered manifests against `policy.rego`
- `just unit-test <chart>` -- helm-unittest specs under `charts/<chart>/tests/`
- `just integration-test <chart>` -- spread/LXD integration run
- `just test <chart>` -- all of the above for one chart
- `just test-all` -- every chart

Rock inspection helpers: `just find-rock <image>`, `just get-rock-entrypoint <image>`,
`just get-rock-filesystem <image>`, `just get-rock-metadata <image>`.

Before opening a PR, run `just test <chart>` for any chart you touched.

## Conventions

- **Charts use rocks.** Images must reference Canonical Ubuntu rocks, pinned by
  digest -- never a floating `:latest` tag (the policy denies it).
- **Policy is enforced.** Rendered workloads (`Deployment`/`StatefulSet`/`DaemonSet`)
  must set resource limits and the `app.kubernetes.io/name` label, and should
  define a readiness probe. See `policy.rego`.
- **One chart per directory** under `charts/`, each with its own `README.md`.
- **Keep templates minimal** -- every template should have a clear, required purpose.
- **Commits** follow [Conventional Commits](https://www.conventionalcommits.org/).
- **PRs** stay small and focused -- avoid bundling multiple charts or features.
  See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for full PR etiquette and the CLA.

## Skills

Chart work is packaged as discrete [Agent Skills](https://agentskills.io/specification)
under `.agents/skills/`. Each is a folder with a `SKILL.md` (name, description,
instructions) plus helper `scripts/`. A conforming agent discovers them
automatically; consult the relevant one before starting a task.

| Skill                   | Purpose                                          | Path                                            |
| ----------------------- | ------------------------------------------------ | ----------------------------------------------- |
| `ubuntu-helm-creator`   | Generate Helm charts backed by Ubuntu rocks      | `.agents/skills/ubuntu-helm-creator/SKILL.md`   |
| `ubuntu-helm-validator` | Validate charts (upstream + Canonical checks)    | `.agents/skills/ubuntu-helm-validator/SKILL.md` |
| `ubuntu-helm-docs`      | Generate/update a chart's `README.md`            | `.agents/skills/ubuntu-helm-docs/SKILL.md`      |
| `ubuntu-helm-analyzer`  | Analyze a chart and extract an ordered feature list | `.agents/skills/ubuntu-helm-analyzer/SKILL.md` |

The underlying scripts are also exposed as `just` targets, so the same
validation runs whether driven by an agent or a human.

For a ready-made persona that drives these skills end to end, see the
[Helm Crafter Agent](.agents/agents/helm-crafter/agent.md).
