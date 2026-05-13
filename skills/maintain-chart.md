# Skill: maintain-chart

**Purpose**: Autonomous maintenance workflow — update a chart's image digest, validate, regenerate documentation, and open a Pull Request or post a failure comment.

## When to invoke

Triggered by the `agent-maintain.yml` GitHub Actions workflow when a `digest-update` Issue is opened.

## Inputs (from issue body)

```
chart: <chart-name>
image: <image>:<tag>
old_digest: sha256:...
new_digest: sha256:...
```

## Workflow

### Step 1 — Update image digest

In `charts/<chart-name>/values.yaml`, find the `image.digest` field and update it to `<new-digest>` (the `sha256:...` value from the issue body). Do NOT modify `image.tag`.

Per `AGENTS.md`, `image.digest` is the canonical digest pin for each chart. The deployment template will use it as `<repository>:<tag>@<digest>` automatically.

### Step 2 — Validate chart

Invoke skill: `helm-toolkit` (helm-validator)  
Read the remote SKILL.md and follow its full validation workflow.  
On failure: read the error, apply a targeted fix, retry (max 3). If same error recurs unchanged, try a different approach.

### Step 3 — Regenerate documentation

Invoke skill: `generate-documentation`  
Write updated `charts/<chart-name>/README.md`

### Step 4a — On success: Open Pull Request

Commit changes to branch `digest-update/<chart-name>-<short-digest>`.  
Open a PR with:
- Title: `chore(<chart-name>): update image digest to <short-digest>...`
- Body: new digest, old digest, link to originating Issue, test result summary
- Closes the originating Issue

### Step 4b — On failure (all retries exhausted): Post Issue comment

Post a structured failure comment on the originating Issue:
```
## Maintenance Agent: Unable to update chart

**Chart**: `<chart-name>`
**New digest**: `<new-digest>`
**Failure reason**: <last error encountered>

Manual intervention required.
```

Do NOT open a PR if tests cannot pass.
