# Contributing to Ubuntu Helm Charts

We are excited to accept contributions to the `canonical/helm-charts` repository from anyone! This repository is structured to ensure a familiar, low-barrier entry point for potential contributors.

> [!NOTE]
> The repository is currently maintained by the Rockcrafters team, who sets the directions and priorities of the project, but other Canonical teams and community members are expected to contribute and potentially maintain their own charts.

## Code of Conduct
This project and everyone participating in it must follow a [Code of Conduct](https://ubuntu.com/community/docs/ethos/code-of-conduct). By participating, you are expected to uphold this code.

## Canonical Contributor License Agreement (CLA)
Before creating a pull request you should sign the [Canonical contributor license agreement](https://ubuntu.com/legal/contributors). It is the easiest way for you to give us permission to use your contributions.

## Report an issue or open a request
If you find a bug or feature gap in this project, look for it on the [project's GitHub issues](https://github.com/canonical/helm-charts/issues) first. If you have fresh input, add your voice to the issue.

If the bug or feature doesn't have an issue, we invite you to [open one](https://github.com/canonical/helm-charts/issues/new).


## How to contribue
`canonical/helm-charts` uses a forking, feature-based workflow. Before making a contribution, there's work one
can do on their local system to assert the quality and
functionality of their changes.

Further testing is then performed by the project's CI
system, within the context of each Pull Request.

### Local setup

It's recommended to make changes on your own fork first.
If you don't have one yet, [create it](https://github.com/canonical/helm-charts/fork).

Next, clone the project, and make sure to follow the steps
described in the ["Get started" guide](README.md).


### Chart Structure Guidelines
* Place your chart within the `charts/` directory.
* Ensure your chart lives in its own `<chart-name>` directory.
* Provide chart-specific documentation in a `README.md` file within your chart's directory.


### Commit Conventions
Please format your commits following the [conventional commit](https://www.conventionalcommits.org/en/v1.0.0/#summary) style.

### Test your changes
Apart from any pre-commit checks that may run when committing
your changes, please also make sure to test them before
opening a new Pull Request.

<!-- You can run a quick test by doing `just test-fast`. -->

### Pull Request Etiquette
Once you're ready to open a PR, please make sure you abide by the following rules:

 - use the draft mode if your PR is not yet ready to be reviewed,
 - provide good PR descriptions,
   - if you have inter-dependent PRs, make those dependencies explicit in the PRs' descriptions,
 - keep an eye out for CI failures. Preemptively fixing any failing checks will save you and the reviewers some time,
 - if possible, use "Labels" to help navigate and prioritize the reviews,
 - do not force push once you already have review comments,
 - keep PRs small and focused! I.e. avoid introducing multiple charts or working on multiple features/fixes on the same PR,
 - you can close a review comment if you applied the proposed change. Otherwise, or when in doubt, you should simply reply and let the reviewers resolve it.