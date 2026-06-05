# Skill: inject-feature

**Purpose**: Inject a single feature from the feature list into the working chart directory. Update templates and values as needed.


## Inputs (read from context)

 - Feature definition that is compliant with the output format described in the `analyse-reference-chart` skill, as well as
 - The <chart> and chart directory where the feature should be injected
 - The reference chart being used for feature comparison

## How to inject

1. **Read** the feature's source template(s) from the reference chart
2. **Adapt** them to the working chart's conventions:
   - Replace hardcoded names with `{{ include "<chart>.fullname" . }}` references
   - Replace hardcoded labels with `{{ include "<chart>.labels" . | nindent N }}`
   - Ensure all values are exposed in `values.yaml` with sensible defaults
   - Apply PSS-Restricted security context if the feature adds a container
3. **Write** the adapted template(s) to the working chart's `templates/` directory
4. **Update** `values.yaml` — add new keys for this feature, with defaults that keep the feature disabled by default (e.g., `ingress.enabled: false`)
5. **Update** `values.schema.json` **ONLY** if it exists already, adding the JSON Schema entries for the new values keys
6. **Do NOT modify** `Chart.yaml`, `_helpers.tpl` (unless adding new named template needed for this feature), or any existing template that was already passing tests

## Minimal injection principle

Only add what the feature strictly requires. Do not add related-but-optional capabilities. If the reference chart's version of a feature has bloat (commented-out options, rarely-used sub-features), omit the bloat.
