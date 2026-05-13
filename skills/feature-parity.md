# Skill: feature-parity

**Purpose**: Entry point for the Iterative Feature Parity workflow. Rebuilds a reference chart from scratch, injecting and testing one feature at a time, with self-directed retries.

## Trigger

Natural language: "Generate a feature-parity Helm chart for `<name>` using `<reference-chart-path>` as reference [and Rock image `<ref>`]"

## Complete workflow

### Step 1 — Rock inspection (if Rock image provided)

Invoke skill: `inspect-rock` → capture PebblePlan YAML.

### Step 2 — Analyse reference chart

Invoke skill: `analyse-reference-chart` with the reference chart path.  
Output: ordered feature list YAML (see skill prompt for format).

### Step 3 — Generate minimal base chart

Invoke skill: `helm-toolkit` (helm-generator) with Canonical overrides from `AGENTS.md`.  
This is the starting point — NOT a copy of the reference chart.

### Step 4 — Validate base chart

Invoke skill: `helm-toolkit` (helm-validator). Fix immediately if failing (base must be clean before feature injection).

### Step 5 — Feature injection loop

For each feature in the ordered feature list:

```
current_attempts = 0
feature_status = "pending"

while feature_status == "pending":
  current_attempts += 1

  invoke inject-feature(feature)

  result = invoke helm-toolkit (helm-validator)
  if result == FAIL:
    read error output, diagnose root cause, apply targeted fix
    if current_attempts >= 5:
      feature_status = "dropped"
      record final failure reason
    continue

  feature_status = "succeeded"

record feature outcome
```

**CRITICAL**: Never inject the next feature until the current one is either `succeeded` or `dropped`.  
**CRITICAL**: If the same error recurs unchanged across two consecutive attempts, try a different approach — do not repeat the same fix.

### Step 6 — Generate documentation

Invoke skill: `generate-documentation`  
Write `charts/<chart-name>/README.md`

### Step 8 — Commit

```
feat(<chart-name>): generate feature-parity Helm chart

Succeeded: <N> features
Dropped: <M> features
See REPORT.md for details
```

## Success criteria

- [ ] Output chart is NOT a copy of the reference (starts from minimal base)
- [ ] Every feature injection was followed by a validation run before the next
- [ ] No feature exceeded 5 total attempts
- [ ] All features accounted for in `REPORT.md`
- [ ] `README.md` documents 100% of values
