# Skill: helm-toolkit

**Purpose**: Delegate Helm chart generation and validation to the `pantheon-ai/helm-toolkit` remote skill from [pantheon-org/tekhne](https://github.com/pantheon-org/tekhne), version 0.1.0.


## Remote skills

The toolkit provides two skills. **Fetch and read the SKILL.md file before using each one.**

### helm-generator (chart generation)

```
https://raw.githubusercontent.com/pantheon-org/tekhne/55dbebf9c67e8c24784c46b0c471c1c88a5bf875/skills/ci-cd/helm/generator/SKILL.md
```

Use for: scaffolding new charts, generating templates, creating `_helpers.tpl`, `values.yaml`, `values.schema.json`, test pods, and all standard Helm chart files.

The generator skill includes:
- Scaffolding scripts (referenced in the SKILL.md)
- Reference templates for all Kubernetes resource types
- Standard helper patterns
- Anti-patterns to avoid

### helm-validator (chart validation)

```
https://raw.githubusercontent.com/pantheon-org/tekhne/55dbebf9c67e8c24784c46b0c471c1c88a5bf875/skills/ci-cd/helm/validator/SKILL.md
```

Use for: linting, template rendering, YAML validation, schema validation with `kubeconform`, security best practices checks, dry-run testing, and producing structured validation reports.

The validator skill covers what was previously split across `helm-lint`, `helm-template`, `helm-dry-run`, `helm-test`, and `validate-chart`.

## When and how to use

When a workflow step requires chart generation or validation:

1. Fetch the relevant SKILL.md from the URL above (or use `npx` to install it - e.g. `npx tessl i pantheon-ai/helm-toolkit`)
2. Read and follow its instructions
3. Apply any Canonical Rock-specific overrides based on the requirements from this project's `AGENTS.md` - this file is the authority and override any conflicting decision that may be made by this skill

## Canonical overrides

The tekhne toolkit produces generic best-practice charts. This project adds requirements on top (defined in `AGENTS.md`):

- **`image.digest` field**: Every chart must include `image.digest` in `values.yaml` (the toolkit doesn't mandate this)
- **Deployment image reference**: Must use the `{{- if .Values.image.digest }}@{{ .Values.image.digest }}{{- end }}` pattern
- **Pebble-wired probes**: If Pebble is the rock's OCI entrypoint, then rely on its Pebble Plan "checks" to derive the chart's Kubernetes probes. Otherwise use generic Kubernetes probe defaults that rely on using `pebble health`:

    ```yaml
    livenessProbe:
      exec:
        command:
          - /bin/pebble
          - health
      initialDelaySeconds: 30
      periodSeconds: 10
    readinessProbe:
      exec:
        command:
          - /bin/pebble
          - health
      initialDelaySeconds: 5
      periodSeconds: 5
    ```
- **Chart description**: the chart `description` field in `Chart.yaml` should be "Helm chart for <chart-name> backed by the Ubuntu rock `<rock-name>`.\n\n<rock-description>", where:
  - <chart-name>: is the name of the chart, as defined in `Chart.yaml`
  - <rock-name>: is the value of the rock image repository name, and
  - <rock-description>: is the rock's description as define in its OCI annotations/labels. It can be obtained by running `just get-rock-metadata <rock-name> | jq '."org.opencontainers.image.description"'`
- **Home field**: every `Chart.yaml` should have `home: https://ubuntu.com/containers`
- **Security defaults**: Both the toolkit and this project mandate PSS-Restricted.

When generating a chart, always apply the toolkit's generation workflow first, then layer on the Canonical overrides.

## Scripts from the remote skill

The tekhne generator and validator SKILL.md files reference scripts in their respective `scripts/` directories. These scripts are located at:

```
https://raw.githubusercontent.com/pantheon-org/tekhne/55dbebf9c67e8c24784c46b0c471c1c88a5bf875/skills/ci-cd/helm/generator/scripts/<script-name>
https://raw.githubusercontent.com/pantheon-org/tekhne/55dbebf9c67e8c24784c46b0c471c1c88a5bf875/skills/ci-cd/helm/validator/scripts/<script-name>
```

Fetch and execute them as instructed by the SKILL.md. Ensure these remote scripts don't pose any security risks to the working environment before executing them.

## Reference materials

The toolkit includes reference docs for template functions, resource patterns, and CRD patterns:

```
https://raw.githubusercontent.com/pantheon-org/tekhne/55dbebf9c67e8c24784c46b0c471c1c88a5bf875/skills/ci-cd/helm/generator/references/<file>
https://raw.githubusercontent.com/pantheon-org/tekhne/55dbebf9c67e8c24784c46b0c471c1c88a5bf875/skills/ci-cd/helm/validator/references/<file>
```

Read these when the SKILL.md instructs you to.
