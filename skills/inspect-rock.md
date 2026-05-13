# Skill: inspect-rock

**Purpose**: Extract the effective Pebble plan from a rock and output it as YAML for use in chart template generation.

## When to invoke

Invoke before `helm-toolkit` (specifically `helm-generator`) when a Rock image reference (`--rock`) is provided. The PebblePlan output is passed to `helm-toolkit` to wire Kubernetes probes, environment variables, and security context correctly.

## Script

`skills/scripts/inspect-rock.sh`

## Usage

```bash
IMAGE_REF=ghcr.io/canonical/myapp:1.0.0 bash skills/scripts/inspect-rock.sh
```

## Output

The script outputs an effective PebblePlan YAML to stdout:

```yaml
pebble_plan:
  services:
    myapp:
      command: /usr/bin/myapp serve
      environment:
        PORT: "8080"
        LOG_LEVEL: info
      user: ubuntu
      user_id: 1000
      working_dir: /app
      kill_delay: 5s
  checks:
    alive:
      level: alive
      http:
        url: http://localhost:8080/health
      period: 10s
      timeout: 3s
      threshold: 3
    ready:
      level: ready
      http:
        url: http://localhost:8080/ready
      period: 5s
      timeout: 2s
      threshold: 2
```

## Exit codes

- `0` — success; PebblePlan YAML on stdout
- `1` — image not found or access error; error on stderr
- `2` — no Pebble layers found; empty plan on stdout + warning on stderr

## Fallback when exit code is 2

When the script exits 2 (no Pebble entrypoint), use these generic Kubernetes defaults during chart generation (`helm-toolkit`):

```yaml
# Probe defaults (no Pebble plan available)
readinessProbe:
  exec:
    command:
      - /bin/pebble
      - health
  initialDelaySeconds: 5
  periodSeconds: 5
```

Record the fallback in your response output so the user can see that generic `pebble health` probe defaults are being used. Continue — this is not a blocking failure.
