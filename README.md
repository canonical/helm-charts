# Ubuntu Helm Charts

Welcome to the `canonical/helm-charts` repository! This project is a community-driven initiative to serve a collection of [Helm charts](https://helm.sh/) for [Ubuntu rocks](https://ubuntu.com/containers/docs).

> [!NOTE]
> Some of the chart in these repo have been inherited from the upstream
> https://github.com/bitnami/charts project. Such charts shall inherit their
> original license and copyrights.

## Get started

Set your local dev environment by:

  1. installing [`just`](https://just.systems/man/en/prerequisites.html) (e.g. `snap install just --classic`), and
  2. running `just setup`.


## Distribution
Upon landing on the default branch, newly contributed Helm charts are versioned, packaged, and published to GHCR.

## Contributing
We welcome contributions! Please read [`CONTRIBUTING.md`](./CONTRIBUTING.md) for details on our code of conduct, the CLA requirement, and the process for submitting Pull Requests to us.

---

## Helm Crafter Agent

This repository includes a **Helm Crafter Agent** — an AI-powered assistant that generates, validates, documents, and maintains Helm charts for applications backed by Ubuntu rocks.

The agent is composed of four discrete skills:

| Skill | Purpose |
|-------|---------|
| `ubuntu-helm-creator` | Generate Helm charts backed by Ubuntu rocks |
| `ubuntu-helm-validator` | Validate charts (upstream + Canonical checks) |
| `ubuntu-helm-docs` | Generate/update `README.md` for a chart |
| `ubuntu-helm-analyzer` | Analyze a chart and extract ordered feature list |

See [`AGENTS.md`](./AGENTS.md) for the full agent specification and workflows.
