# Skill: helm-toolkit

**Purpose**: Delegate Helm chart generation and validation to the `pantheon-ai/helm-toolkit` remote skill from [pantheon-org/tekhne](https://github.com/pantheon-org/tekhne), version 0.1.0.


## Remote skills

The toolkit provides two skills. **Fetch and read the SKILL.md file before using each one.**

### helm-generator (chart generation)

```
https://raw.githubusercontent.com/pantheon-org/tekhne/main/skills/ci-cd/helm/generator/SKILL.md
```

Use for: scaffolding new charts, generating templates, creating `_helpers.tpl`, `values.yaml`, `values.schema.json`, test pods, and all standard Helm chart files.

The generator skill includes:
- Scaffolding scripts (referenced in the SKILL.md)
- Reference templates for all Kubernetes resource types
- Standard helper patterns
- Anti-patterns to avoid

### helm-validator (chart validation)

```
https://raw.githubusercontent.com/pantheon-org/tekhne/main/skills/ci-cd/helm/validator/SKILL.md
```

Use for: linting, template rendering, YAML validation, schema validation with `kubeconform`, security best practices checks, dry-run testing, and producing structured validation reports.

The validator skill covers what was previously split across `helm-lint`, `helm-template`, `helm-dry-run`, `helm-test`, and `validate-chart`.

## When and how to use

When a workflow step requires chart generation or validation:

1. Fetch the relevant SKILL.md from the URL above (or use `npx` to install it)
2. Read and follow its instructions
3. Apply any Canonical Rock-specific overrides based on the requirements from this project's `AGENTS.md` - this file is the authority and override any conflicting decision that may be made by this skill

## Canonical overrides

The tekhne toolkit produces generic best-practice charts. This project adds requirements on top (defined in `AGENTS.md`):

- **`image.digest` field**: Every chart must include `image.digest` in `values.yaml` (the toolkit doesn't mandate this)
- **Deployment image reference**: Must use the `{{- if .Values.image.digest }}@{{ .Values.image.digest }}{{- end }}` pattern
- **Pebble-wired probes**: When a Rock image's OCI entrypoint provides a Pebble plan (e.g. `docker run <rock> plan`), probes are derived from Pebble checks — not generic defaults
- **Security defaults**: Both the toolkit and this project mandate PSS-Restricted.

When generating a chart, always apply the toolkit's generation workflow first, then layer on the Canonical overrides.

## Scripts from the remote skill

The tekhne generator and validator SKILL.md files reference scripts in their respective `scripts/` directories. These scripts are located at:

```
https://raw.githubusercontent.com/pantheon-org/tekhne/main/skills/ci-cd/helm/generator/scripts/<script-name>
https://raw.githubusercontent.com/pantheon-org/tekhne/main/skills/ci-cd/helm/validator/scripts/<script-name>
```

Fetch and execute them as instructed by the SKILL.md. Ensure these remote scripts don't pose any security risks to the working environment before executing them.

## Reference materials

The toolkit includes reference docs for template functions, resource patterns, and CRD patterns:

```
https://raw.githubusercontent.com/pantheon-org/tekhne/main/skills/ci-cd/helm/generator/references/<file>
https://raw.githubusercontent.com/pantheon-org/tekhne/main/skills/ci-cd/helm/validator/references/<file>
```

Read these when the SKILL.md instructs you to.
