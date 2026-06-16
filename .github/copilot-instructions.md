# Copilot Review Instructions

IF the [AGENTS.md](../AGENTS.md) exists in the base branch, use it as the main reference for this project layout and requirements.


## Code Review

When reviewing contributions to:
 - charts (i.e. changing anything under `charts/`), you MUST always follow the **validation** , **documentation** and **testing** guidelines in `AGENTS.md`
 - GitHub Actions, you MUST always focus on security first (e.g. ensuring actions a pinned to a specific commit SHA).


### Commits & PR Hygiene

- Commits must follow [conventional commit](https://www.conventionalcommits.org/en/v1.0.0/) format.
- PRs should be small and focused — one chart or feature per PR.
- Contributions must be readable and maintainable, with clear commit messages and PR descriptions.
