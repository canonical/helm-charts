# Project Report

## Session: Task Generation (2026-05-13)

### Task
Generate `tasks.md` from all plan artifacts for the Helm Architect Agent.

### Output
`specs/001-helm-architect-agent/tasks.md` — 45 tasks across 7 phases.

### Summary
| Phase | Tasks | Purpose |
|---|---|---|
| Phase 1: Setup | T001–T006 | Repository skeleton scaffolding |
| Phase 2: Foundational | T007–T014 | Agent identity, Ruminator, Rock inspection, Spread backend |
| Phase 3: US1 (P1 MVP) | T015–T027 | Zero-to-One chart generation — all Helm skills + documentation |
| Phase 4: US2 (P2) | T028–T032 | Feature Parity mode with Ruminator retries and debrief |
| Phase 5: US3 (P3) | T033–T035 | Standalone documentation generation enhancements |
| Phase 6: US4 (P4) | T036–T039 | Autonomous CI/CD — digest poll + agent maintain workflows |
| Phase 7: Polish | T040–T045 | Edge cases, fallbacks, example task, repo README |

### Key decisions in task breakdown
- Skills are split into **prompt file** (`.github/skills/*.md`) + **shell script** (`.github/scripts/*.sh`) pairs; `generate-templates` and Ruminator skills are prompt-only (Copilot writes files or reads context directly)
- `copilot-instructions.md` is the single source of truth for agent behaviour; each user story phase extends it
- US2 reuses US1 skills — ordered dependency noted but US4 CI workflows can be written concurrently
- `rockcraft.skopeo` pre-flight check built into `inspect-rock.sh`
- Ruminator session ID convention: `YYYYMMDD-HHMMSS-<chart-name>`

---

## Session: Plan Adjustments (2026-05-13)

### Changes requested
Three corrections applied to all plan artifacts after initial plan generation:

1. **No agent framework** — LangGraph (and all other Python LLM frameworks) removed. The agent runtime is **GitHub Copilot** operating natively on this Git repository via Copilot Workspace / Copilot coding agent. Agent behaviour is expressed through `.github/copilot-instructions.md`, skill prompt files (`.github/skills/*.md`), and shell scripts (`.github/scripts/*.sh`). No Python package, CLI entrypoint, or external runtime dependency exists.

2. **`crane` → `rockcraft.skopeo`** — Rock OCI image inspection now uses `rockcraft.skopeo`, the skopeo binary bundled with the `rockcraft` snap (already present on any machine with Rockcraft installed). Commands: `rockcraft.skopeo inspect oci-archive:<file>` or `rockcraft.skopeo inspect docker://docker.io/...`. No separate tool install required.

3. **PR creation → GitHub Copilot** — The `peter-evans/create-pull-request` action and associated PAT/App token management removed. Pull Requests are opened by GitHub Copilot (coding agent) directly using its built-in repository write access during the `agent-maintain.yml` workflow.

### Files updated
- `specs/001-helm-architect-agent/research.md` — Section 1 rewritten (Copilot as runtime), Section 2 updated (rockcraft.skopeo), Section 4 updated (rockcraft.skopeo for digest polling, Copilot for PR creation)
- `specs/001-helm-architect-agent/plan.md` — Summary, Technical Context, Project Structure all revised; `agent/` Python package removed; `.github/` Copilot structure added; Ruminator as committed Markdown files
- `specs/001-helm-architect-agent/contracts/skill-api.md` — Rewritten: skills are now Copilot prompt files + shell scripts; LangGraph tool nodes removed
- `specs/001-helm-architect-agent/contracts/cli-interface.md` — Renamed/rewritten as Workflow & Trigger Interface; CLI entrypoint removed; Copilot direct invocation and GHA workflow contracts documented
- `specs/001-helm-architect-agent/quickstart.md` — Python/CLI sections removed; Copilot invocation pattern documented; `rockcraft.skopeo` inspection commands added
- `specs/001-helm-architect-agent/spec.md` — FR-001, FR-004, FR-005, FR-019, FR-024–027, Assumptions all updated to reflect Copilot-native agent and rockcraft.skopeo

---

## Session: Execution Plan — Phase 0 & 1 (2026-05-13)

### Task
Generate the full implementation plan for the Helm Architect Agent from `specs/001-helm-architect-agent/spec.md`.

### Actions
- Ran `setup-plan.sh` to scaffold `plan.md` at `specs/001-helm-architect-agent/plan.md`
- Ran 5 parallel research tasks (LLM frameworks, Rock/Pebble inspection, Spread, GHA CI patterns, Helm best practices)
- Consolidated research into `research.md`
- Produced Phase 1 design artifacts: `data-model.md`, `contracts/cli-interface.md`, `contracts/skill-api.md`, `quickstart.md`
- Completed `plan.md` with Technical Context, Constitution Check (no violations), Project Structure
- Updated `AGENTS.md` to reference `specs/001-helm-architect-agent/plan.md`

### Key Decisions
- **LangGraph** chosen as agent framework (AutoGen excluded — maintenance mode; MAF excluded — Azure bias)
- **`crane`** for Rock OCI inspection; **`kind`** for ephemeral clusters; **Spread `adhoc` backend** for E2E tests
- **`peter-evans/create-pull-request@v8`** for CI PRs; **`crane digest`** for digest polling; committed `digests/last-known.json` for state
- Single Python project layout under `agent/`; 9 discrete skill modules; LangGraph `MemorySaver` for Ruminator session state

### Outcome
Plan complete and all NEEDS CLARIFICATION resolved. Ready for `/speckit.tasks`.

---

## Session: Agent Framework Research (2026-05-13)

### Task
Research open-source LLM agent frameworks suitable for building an autonomous agentic system in Python.

### Requirements
- Composable tools/skills
- Short-term session memory
- CLI tool integration (helm, docker/OCI, spread)
- Active community support (2025-2026)

### Frameworks Evaluated
1. LangGraph (langchain-ai/langgraph)
2. CrewAI (crewAIInc/crewAI)
3. AutoGen (microsoft/autogen)
4. Microsoft Agent Framework (microsoft/agent-framework) — AutoGen successor
5. Agno (agno-agi/agno)

### Key Findings

**AutoGen** was discovered to be in maintenance mode as of 2025 — no new features, community-managed only. Microsoft redirects new users to **Microsoft Agent Framework (MAF)**. AutoGen was excluded from recommendations.

**MAF** is the enterprise AutoGen successor with strong .NET focus (~50% of codebase is C#) and heavy Azure/Foundry bias. Technically capable but not ideal for a Python-first, cloud-agnostic system.

**LangGraph** (31.9k stars, v1.2.0 May 2026) is the strongest option for systems requiring explicit execution control, durable state, and complex branching logic — well-suited for infrastructure automation workflows.

**CrewAI** (51.3k stars, v1.14.4 April 2026) is the easiest to onboard, has the largest certified developer community, and suits role-based multi-agent decomposition.

**Agno** (40.1k stars, v2.6.5 May 2026, Apache-2.0) is distinctive for its production API-first model, native human-approval flows for shell commands, and Workspace tool — uniquely suited for safe CLI tool integration.

### Decisions
- **Primary recommendation:** LangGraph — best explicit control for infrastructure automation workflows
- **Secondary recommendation:** CrewAI — best for role-based agent decomposition with lower complexity
- **Honorable mention:** Agno — best for production API exposure and safe CLI gating
- **Excluded:** AutoGen (maintenance mode), MAF (Azure-biased, Python secondary)

### Output
Full structured analysis written to `research.md`.

---

## Session: Spread Framework Research (2026-05-13)

### Task
Research Canonical's Spread testing framework for use as the integration testing backbone for the Helm Architect Agent's ephemeral-cluster smoke test infrastructure.

### Key Findings

**Project structure**: `spread.yaml` at repo root + `suites/<suite>/<task>/task.yaml`. No generator required — plain YAML and shell scripts.

**Backend types**: lxd, qemu, google, openstack, linode, **adhoc**. The `adhoc` backend is the only viable option for ephemeral Kubernetes clusters because its `allocate`/`discard` scripts are fully user-defined shell.

**Kubernetes integration**: Spread has no native k8s integration. The AdHoc pattern calls `kind create cluster` (or microk8s/k3s) in `allocate`, exposes SSH on localhost via `ADDRESS localhost:22`, and tasks use `helm`/`kubectl` with `KUBECONFIG` pointing to the generated kubeconfig. The cluster is destroyed in `discard`.

**Minimal Helm smoke task**: `summary` + `prepare` (tooling + namespace) + `execute` (lint → dry-run → install → verify via `MATCH`) + `restore` (uninstall + delete namespace, always with `|| true`) + `kill-timeout`.

**Teardown**: `restore` always runs even on failure. A failing `restore` marks the system broken and stops subsequent jobs. Write defensively.

### Decisions
- **Cluster technology**: `kind` recommended (fastest, Docker-based, trivial install/delete) over microk8s (snap dep) and k3s (more complex).
- **Isolation model**: Cluster-per-run via adhoc lifecycle; namespace-per-task for scale optimisation later.
- **Assertion helper**: Use Spread's built-in `MATCH`/`NOMATCH` over raw `grep` for better failure output.

### Output
Full structured research written to `specs/001-helm-architect-agent/research.md` with Decision/Rationale/Alternatives across all five questions.

---

## Session: CI/CD Pattern Research (2026-05-13)

### Task
Research best-practice GitHub Actions patterns for the autonomous maintenance CI/CD pipeline (spec FR-024/FR-025).

### Topics Covered
1. Scheduled OCI registry digest polling
2. Creating GitHub Issues from a workflow
3. Triggering a second workflow from `issues: opened` with label filtering
4. Persisting last-known digest state between runs
5. Opening Pull Requests from within a workflow

### Key Decisions
- **Digest polling:** `crane digest` via `imjasonh/setup-crane` — single command, no layer pull, registry-agnostic.
- **Issue creation:** `gh issue create` with `GITHUB_TOKEN` (`issues: write`) — pre-installed on all hosted runners, no extra action needed.
- **Workflow trigger:** `on: issues: types: [opened]` + job `if: contains(github.event.issue.labels.*.name, 'digest-update')` — label applied at issue creation time to avoid race.
- **State persistence:** Committed `digests/last-known.json` file — durable (no 7-day TTL), git-auditable, visible. Requires care to avoid recursive trigger.
- **PR creation:** `peter-evans/create-pull-request@v8` — handles idempotent branch + PR lifecycle; PAT/App token needed for CI checks to run on the PR.

### Output
Full structured Decision/Rationale/Alternatives findings written to `specs/001-helm-architect-agent/research.md`.

---

## Session: Helm Chart Best Practices Research (2026-05-13)

### Task
Research Helm chart structure, minimal viable chart generation, test pods, `_helpers.tpl` patterns, security hardening, and `helm lint` behavior for 2025–2026.

### Sources
- Helm v4.1.1 official documentation (helm.sh/docs)
- Topics: Charts, Chart Tests, Best Practices (Templates, Pods/PodTemplates), `helm lint` command reference

### Key Findings

**Minimum file set**: Only `Chart.yaml` is strictly required by Helm. A functional, configurable chart requires `Chart.yaml` + `values.yaml` + at least one template. Best practice adds `_helpers.tpl`, `values.schema.json`, `NOTES.txt`, `serviceaccount.yaml`, and `templates/tests/test-connection.yaml`.

**Test pods**: Live under `templates/tests/`, are Kubernetes Pod manifests with `"helm.sh/hook": test` annotation and `restartPolicy: Never`. Container must exit 0 for the test to pass. Run via `helm test <release>`.

**`_helpers.tpl` patterns**: All `{{ define }}` blocks must be namespaced with the chart name (e.g., `mychart.fullname`) because defined templates are globally scoped across all subcharts. Standard helpers include `fullname`, `name`, `labels`, `selectorLabels`, `chart`, `serviceAccountName`. Selector labels must use only stable values (not `version`).

**Security hardening**: Kubernetes PSS "Restricted" baseline requires `runAsNonRoot`, `allowPrivilegeEscalation: false`, drop ALL capabilities, `seccompProfile: RuntimeDefault`. Add `readOnlyRootFilesystem: true` and explicit resource limits/requests as defense-in-depth.

**`helm lint`**: Validates chart structure, template rendering, YAML validity, Kubernetes manifest shape, `values.schema.json` conformance, and dependency presence. Use `--strict` in CI to promote warnings to errors. Does not check runtime behavior or security posture — pair with `kubesec`/`polaris` for that.

### Output
Structured Decision/Rationale/Alternatives research written to `specs/001-helm-architect-agent/research.md`.

---

## Session: Canonical Rocks & Pebble Research (2026-05-13)

### Task
Research Rock OCI image structure, Pebble layer storage paths, Pebble YAML schema, CLI inspection tools, and programmatic extraction patterns. Five structured topics requested for use in the Helm Architect Agent's Rock/Pebble inspection skills.

### Sources
- Rockcraft documentation (documentation.ubuntu.com/rockcraft)
- Pebble documentation + GitHub (canonical/pebble)
- OCI Image Specification (opencontainers/image-spec)

### Key Findings

**OCI structure**: A Rock is a standard OCI image archive (`.rock` = OCI layout tar). It contains a base Ubuntu layer plus a "prime layer" built from the Rockcraft lifecycle. The prime layer includes the app files and the Pebble binary at `usr/bin/pebble` (rewritten via usrmerge). A metadata layer provides `/.rock/metadata.yaml`.

**Pebble layer path**: Pebble reads static config from `$PEBBLE/layers/` (default: `/var/lib/pebble/default/layers/`). Rockcraft places the baked-in service definition as `001-<rock-name>.yaml`. Files are applied in lexicographic (numeric prefix) order.

**Pebble YAML fields for K8s**: `services.<name>.command` → container command; `services.<name>.environment` → env vars; `services.<name>.user`/`user-id` → securityContext; `checks.<name>` with `level: alive|ready` and `http|tcp|exec` → liveness/readiness probes; `kill-delay` → terminationGracePeriodSeconds.

**Inspection tools**: `skopeo` (daemon-free registry copy + inspect), `crane` (Go library + CLI, best for programmatic layer walking), `oras` (artifact-oriented), `dive` (TUI, manual only).

**Extraction**: Walk all OCI layer tar blobs in manifest order, collect `var/lib/pebble/default/layers/*.yaml`, sort by filename prefix, apply Pebble merge semantics (`override: replace|merge`). Best implemented with `go-containerregistry` (no daemon dependency, works on both `.rock` files and registry refs).

### Output
Structured research written to `specs/001-helm-architect-agent/research.md` (new file, 5 topics with Decision/Rationale/Alternatives).

---

## Session: Full Implementation — Phases 1–7 (2026-05-13)

### Task
Implement all 45 tasks across 7 phases of the Helm Architect Agent, from repository scaffolding through to final polish.

### Phases Completed

#### Phase 1 — Repository Scaffolding (T001–T006)
Created directory skeleton: `charts/`, `spread/suites/helm-smoke/`, `digests/`, `ruminator/`, `.github/skills/`, `.github/scripts/`, `.github/workflows/`. Initialised `digests/last-known.json` as `{}`, `spread/spread.yaml` stub, `.helmignore` for pre-existing charts (`common`, `rabbitmq`).

#### Phase 2 — Foundational (T007–T014)
- `.github/copilot-instructions.md`: Full agent persona, skill index, Ruminator protocol, Zero-to-One and Feature Parity mode workflows, Helm chart standards
- `.github/skills/ruminator-record.md` + `ruminator-query.md`: Session-scoped failure memory protocol
- `.github/skills/inspect-rock.md` + `.github/scripts/inspect-rock.sh`: `rockcraft.skopeo copy` → OCI layout walk → Pebble layer merge → YAML to stdout; exit codes 0/1/2
- `spread/allocate.sh` + `spread/discard.sh` + `spread/spread.yaml`: `kind`-based ephemeral Kubernetes cluster for Spread adhoc backend

#### Phase 3 — US1 Zero-to-One (T015–T027)
- `helm-lint.sh` / `helm-template.sh` / `helm-dry-run.sh` + matching skill prompts
- `spread-run.sh` + `spread-run.md`: CHART_NAME-routed Spread runner with per-task PASS/FAIL output
- `generate-templates.md`: Copilot-only skill for generating the complete 9-file chart skeleton from PebblePlan YAML; PSS-Restricted security defaults enforced
- `generate-documentation.sh`: Python3 values parser extracting YAML comments as descriptions; `(inferred)` marker for undescribed values
- `generate-documentation.md`: Skill to produce full README.md from script output
- `zero-to-one.md`: 8-step end-to-end workflow skill

#### Phase 4 — US2 Feature Parity (T028–T032)
- `feature-parity.md`: 10-step iterative injection loop skill with max-5 retry protocol
- `analyse-reference-chart.md`: Feature extraction from a reference chart directory
- `inject-feature.md`: Single-feature template injection with rollback instructions
- `generate-debrief.md`: Structured debrief report skill for succeeded/dropped features

#### Phase 5 — US3 Documentation (T033–T035)
- `generate-documentation.sh` already supported `(inferred)` via comment extraction
- `generate-documentation.md` updated with inferred-value handling rules
- `copilot-instructions.md` extended with standalone documentation trigger section

#### Phase 6 — US4 CI/CD (T036–T039)
- `.github/workflows/digest-poll.yml`: Hourly cron workflow; `rockcraft.skopeo inspect` per image in `digests/last-known.json`; duplicate-issue guard; `gh issue create --label digest-update`; commits updated digest file with `[skip ci]`
- `.github/workflows/agent-maintain.yml`: `issues: opened` + `digest-update` label guard; parses issue body; updates `values.yaml` digest pin; runs `helm-lint` + Spread; regenerates README; opens PR on success, posts failure comment on failure
- `.github/skills/maintain-chart.md`: Agent skill prompt for the maintenance workflow
- `digests/README.md`: Schema documentation, watch-list setup instructions, polling/maintenance lifecycle explanation

#### Phase 7 — Polish (T040–T045)
- `copilot-instructions.md`: Added Pebble fallback section (exit 2 → generic probes + `ruminator-record`); deprecated Kubernetes API handling (treat as droppable feature, record substitution if possible)
- `spread/suites/helm-smoke/example-chart/task.yaml`: Worked example Spread task with `prepare`/`restore`/`|| true` guards, pod-running, service-endpoint, helm-test, and security-context subtasks
- `agent-maintain.yml`: Duplicate-PR guard step added before checkout — checks for open PRs matching `chore(<chart>): update image digest`; posts skip comment on duplicate
- `README.md`: Extended existing repo README with Helm Architect Agent section — mode table, prerequisites table, quick start, skill index, CI/CD workflow table

### Key Decisions

| Decision | Rationale |
|---|---|
| Agent runtime = GitHub Copilot only | No external framework (LangGraph, CrewAI) needed; Copilot coding agent supports autonomous multi-file writes |
| `rockcraft.skopeo` not `crane` | Bundled with `rockcraft` snap — no separate install; matches toolchain already used by Rockcraft |
| Ruminator = committed Markdown | Persists across agent invocations; reviewable by humans; no database dependency |
| `digests/last-known.json` as state | Survives runner restarts; human-editable; `[skip ci]` commit avoids workflow loops |
| Duplicate-issue guard in digest-poll | `gh issue list --search` by title prefix; prevents duplicate open issues per image per tag |
| Duplicate-PR guard in agent-maintain | `gh pr list --search` by title prefix; prevents concurrent maintenance runs on same chart |
| Pebble fallback = generic probes | Exit 2 is non-blocking; agent logs `escalated` (not `failed`) to Ruminator and continues |
| Deprecated API = droppable feature | Avoids injecting broken YAML; debrief records substitution if a supported API exists |

### Files Created / Modified (Phases 1–7)

**New files** (37):
- `.github/copilot-instructions.md`
- `.github/skills/` — 15 skill prompts
- `.github/scripts/` — 6 shell scripts
- `.github/workflows/digest-poll.yml`, `agent-maintain.yml`
- `spread/spread.yaml`, `spread/allocate.sh`, `spread/discard.sh`
- `spread/suites/helm-smoke/example-chart/task.yaml`
- `digests/last-known.json`, `digests/README.md`
- `ruminator/.gitkeep`
- `specs/001-helm-architect-agent/tasks.md`

**Modified files**:
- `README.md` — added Helm Architect Agent section
- `charts/common/.helmignore`, `charts/rabbitmq/.helmignore` — added for pre-existing charts
- `specs/001-helm-architect-agent/tasks.md` — all 45 tasks marked complete

### Status
All 45 tasks complete. All phases delivered. Agent is ready for activation in a GitHub Copilot-enabled repository.

---

## Session: Design Revision — Ruminator & Digests (2026-05-13)

### Changes

**Removed `ruminator/.gitkeep`**: The `ruminator/` directory no longer has a tracked placeholder. The agent creates it on demand when writing the first session file. Rationale: no reason to pre-create a directory that may never be used; Copilot can create files in new directories without the directory existing first.

**Removed `digests/` directory and `digests/last-known.json`**: The separate digest state file was redundant. Per AGENTS.md, every chart's `values.yaml` already contains an `image.digest` field. The `digest-poll.yml` workflow now iterates over `charts/*/values.yaml`, reads `image.repository`, `image.tag`, and `image.digest` directly, and compares against the remote registry. No external state file is needed — the chart is its own source of truth for the pinned digest.

**Updated `AGENTS.md`**: Added a full "Helm Chart Requirements" section mandating the `image` block schema (repository, tag, digest, pullPolicy), the deployment template digest-wiring pattern, and PSS-Restricted security defaults. Removed Ruminator session file convention — not needed.

**Updated `digest-poll.yml`**: Rewrites the polling loop to glob `charts/*/values.yaml`, skip charts without a `ghcr.io/canonical/` repository, and create `digest-update` issues using the chart's `image.digest` as the baseline.

**Updated `agent-maintain.yml`**: The "Update image digest" step now writes to `image.digest` in `values.yaml` (not `image.tag`), using Python3+re to update the field in place while preserving YAML comments.

**Updated `maintain-chart.md`**: Aligned skill prompt with the new `image.digest`-centric approach.

**Updated `plan.md`, `copilot-instructions.md`, `README.md`**: All references to `digests/last-known.json` and pre-created `ruminator/` directory removed or corrected.

---

## Session: Remove Ruminator (2026-05-13)

### Decision

The Ruminator pattern (writing failure notes to `ruminator/session-*.md` mid-run, then reading them back) was removed entirely.

**Reason**: A GitHub Copilot coding agent operates with a full session context window. Every tool call it made, every error output it received, and every fix it attempted is already in context. Writing that information to a file and reading it back is a roundabout way of using memory the agent already has — it adds file I/O overhead with no benefit. The pattern was cargo-culted from LangGraph/CrewAI, where external memory *is* necessary because those agents have short, stateless contexts.

**What replaced it**: The failure and retry protocol in `copilot-instructions.md` now reads: "read the full error output carefully, identify the root cause, apply a targeted fix, retry. If the same error recurs unchanged, try a different approach." This is self-reflection via context, not via files.

### Files removed
- `.github/skills/ruminator-record.md`
- `.github/skills/ruminator-query.md`

### Files updated (Ruminator references stripped)
- `.github/copilot-instructions.md` — Ruminator Protocol section replaced with Failure and Retry Protocol
- `.github/skills/zero-to-one.md` — session creation step removed; retry steps simplified
- `.github/skills/feature-parity.md` — same; injection loop pseudocode updated
- `.github/skills/helm-lint.md` — On failure section rewritten
- `.github/skills/spread-run.md` — On failure section rewritten
- `.github/skills/inspect-rock.md` — fallback note updated
- `.github/skills/maintain-chart.md` — session creation step removed; retry steps simplified
- `.github/skills/generate-debrief.md` — inputs section no longer references session file
- `AGENTS.md` — Ruminator session file convention removed from chart requirements

---

## Session: Remove Spread, Replace with helm test (2026-05-13)

### Decision

Spread was removed entirely. Replaced with `helm test` + a simple `kind` cluster lifecycle in `helm-test.sh`.

**Reason**: Spread's value was a `prepare`/`execute`/`restore` lifecycle and `MATCH` assertions against an ephemeral kind cluster. But `helm test` already provides a test lifecycle (test pods defined in `templates/tests/`), and the cluster provisioning is just `kind create cluster` — two lines of shell, not a framework. The smoke tests we built in Spread (pod-running, service-endpoint, helm-test, security-context) map directly to:
1. `helm install --wait` (pod-running)
2. Helm test pods in `templates/tests/test-connection.yaml` (service-endpoint, connectivity)
3. `validate-chart.sh` for kubectl-level security assertions that can't be tested from inside a pod

This removes: the `spread` CLI dependency, `spread.yaml` config, `allocate.sh`/`discard.sh`, per-chart `task.yaml` files, and the Spread DSL learning curve. Tests are now portable — they live inside the chart itself.

### Files deleted
- `spread/` directory and all contents (`spread.yaml`, `allocate.sh`, `discard.sh`, `suites/`)
- `.github/scripts/spread-run.sh`
- `.github/skills/spread-run.md`

### Files created
- `.github/scripts/helm-test.sh` — E2E test script: creates kind cluster → `helm install --wait` → verifies pods Running → `helm test` → `validate-chart.sh` → teardown (always, even on failure). Supports `SKIP_CLUSTER` for using an existing cluster and `SKIP_VALIDATE` for skipping security checks.
- `.github/scripts/validate-chart.sh` — Post-install kubectl-level assertions: `runAsNonRoot`, `allowPrivilegeEscalation=false`, `readOnlyRootFilesystem`, `capabilities.drop ALL`, service ClusterIP + endpoints.
- `.github/skills/helm-test.md` — Skill prompt documenting the helm-test workflow, environment variables, when to invoke, and the security validation companion.

### Files updated (Spread references removed)
- `.github/copilot-instructions.md` — Spread replaced with `helm-test` in skill index, workflow steps, and repo layout
- `.github/skills/zero-to-one.md` — "Generate Spread suite" + "Spread E2E test" steps replaced with single "Helm test (E2E)" step
- `.github/skills/feature-parity.md` — injection loop uses `helm-test` instead of `spread-run`
- `.github/skills/maintain-chart.md` — "Spread test" step replaced with "Helm test (E2E)"
- `.github/skills/helm-dry-run.md` — example kubeconfig path and when-to-use note updated
- `.github/skills/inject-feature.md` — references to `spread-run` replaced with `helm-test`
- `.github/workflows/agent-maintain.yml` — `spread-run.sh` step replaced with `helm-test.sh`; `spread` removed from tool install step
- `README.md` — prerequisites table: `spread` removed; `kind` purpose updated; quick start text updated
- `specs/001-helm-architect-agent/plan.md` — project structure, dependencies, testing, and structure decision all updated

---

## Session: Adopt pantheon-ai/helm-toolkit (2026-05-13)

### Decision

Replaced 10 custom Helm skill files and shell scripts with a single `helm-toolkit.md` skill that delegates to the remote `pantheon-ai/helm-toolkit` from [pantheon-org/tekhne](https://github.com/pantheon-org/tekhne).

**Reason**: The project had accumulated many thin skills (`helm-lint.md`, `helm-template.md`, `helm-dry-run.md`, `helm-test.md`, `generate-templates.md`) that were less capable reimplementations of what the tekhne helm-toolkit already provides — a battle-tested helm-generator (chart scaffolding, reference templates, scripts) and helm-validator (10-stage validation including lint, kubeconform schema validation, security checks, CRD detection, and structured reporting). Building custom versions of these was unnecessary.

**What remains**: Only Canonical Rock-specific skills that the toolkit doesn't cover — `inspect-rock`, `generate-documentation`, `zero-to-one`, `feature-parity`, `analyse-reference-chart`, `inject-feature`, `generate-debrief`, `maintain-chart`.

**Integration pattern**: The `helm-toolkit.md` skill instructs the agent to fetch the remote SKILL.md files at runtime via raw GitHub URLs, read them, and follow their instructions. No submodule, no vendored copy. The agent always gets the latest version. Canonical-specific overrides (image.digest field, Pebble-wired probes, digest wiring pattern) are layered on top as documented in `AGENTS.md` and `helm-toolkit.md`.

### Files deleted (10)
- `.github/skills/helm-lint.md`, `helm-template.md`, `helm-dry-run.md`, `helm-test.md`, `generate-templates.md`
- `.github/scripts/helm-lint.sh`, `helm-template.sh`, `helm-dry-run.sh`, `helm-test.sh`, `validate-chart.sh`

### Files created (1)
- `.github/skills/helm-toolkit.md` — remote skill delegation with Canonical override instructions

### Files updated
- `.github/copilot-instructions.md` — skill index reduced from 13 to 9 entries; workflows reference `helm-toolkit` instead of individual skills
- `.github/skills/zero-to-one.md` — generation and validation steps reference `helm-toolkit`
- `.github/skills/feature-parity.md` — injection loop validation references `helm-toolkit`
- `.github/skills/maintain-chart.md` — validation step references `helm-toolkit`
- `.github/skills/inject-feature.md` — rollback instruction references `helm-toolkit` validator
- `.github/workflows/agent-maintain.yml` — custom script steps replaced with inline helm lint + template + kind + helm test
- `README.md` — added `kubeconform` to prerequisites; updated quick start and skill table
- `specs/001-helm-architect-agent/plan.md` — project structure and structure decision updated

### Current skill inventory (9 files)
| Skill | Type |
|---|---|
| `helm-toolkit.md` | Remote delegation (generation + validation) |
| `inspect-rock.md` | Canonical-specific (Pebble extraction) |
| `generate-documentation.md` | Canonical-specific (values table + README) |
| `zero-to-one.md` | Workflow orchestrator |
| `feature-parity.md` | Workflow orchestrator |
| `maintain-chart.md` | CI/CD workflow |
| `analyse-reference-chart.md` | Feature parity sub-skill |
| `inject-feature.md` | Feature parity sub-skill |
| `generate-debrief.md` | Feature parity sub-skill |

### Spec file cleanup (same session)

Updated all spec files to remove stale references to deleted components (Spread, Ruminator, digests/, individual Helm skills). Three approaches used:

1. **Full rewrite** (active reference docs): `quickstart.md`, `contracts/skill-api.md`, `contracts/cli-interface.md` — these are the user-facing reference documents and needed to accurately reflect the current architecture.

2. **Revision notice added** (historical planning docs): `tasks.md`, `spec.md`, `research.md`, `data-model.md` — these are planning artifacts with historical value. A prominent revision notice was added at the top of each, listing exactly which components were removed/replaced and pointing to `REPORT.md` for details. Original content preserved below the notice.

3. **No changes needed** (already updated): `plan.md` was already updated in the toolkit adoption step.

**Verification**: Automated search confirmed all 10 checked files are clean — no stale references to deleted files/skills remain outside of revision notices.

### Consolidate copilot-instructions.md into AGENTS.md (same session)

**Decision**: Made `AGENTS.md` the single source of truth for all agent rules. Previously, `copilot-instructions.md` contained the full agent persona, skill index, workflows, retry protocol, and chart standards, while `AGENTS.md` only contained chart requirements. This was redundant and meant non-Copilot agents (e.g. OpenCode) would miss the workflow/skill definitions.

**What changed**:
- Moved all content from `copilot-instructions.md` (persona, skill index, failure/retry protocol, Zero-to-One mode, Feature Parity mode, Pebble fallback, deprecated API handling, standalone documentation, repo layout) into `AGENTS.md`
- Reduced `copilot-instructions.md` to a single line: "Follow all rules defined in the root `AGENTS.md` file."
- Updated references in `quickstart.md`, `contracts/cli-interface.md`, `plan.md`, `README.md` to point to `AGENTS.md` as the authoritative source

**Rationale**: `AGENTS.md` is read by any agent (Copilot, OpenCode, etc.), while `copilot-instructions.md` is Copilot-specific. Making `AGENTS.md` authoritative ensures all agents get the same rules regardless of runtime.

### Added Copilot prompt files (same session)

Created `.github/prompts/` with two reusable prompt files that appear as slash commands in Copilot Chat:

- **`create-chart.prompt.md`**: Triggers the Zero-to-One workflow. Prompts for application name and optional Rock image reference. Instructs the agent to follow `AGENTS.md` rules and the `helm-toolkit` remote skill.
- **`test-chart.prompt.md`**: Triggers the helm-validator pipeline against an existing chart. Prompts for chart name. Runs all validation stages with retry logic (max 3), prints structured pass/fail summary.

Both prompts defer to `AGENTS.md` as the authoritative rule source.

### Moved .github/scripts/ to skills/scripts/ (same session)

**Decision**: Consolidated shell scripts alongside their skill prompt files. Previously scripts lived in `.github/scripts/` while prompts lived in `skills/`. Now both are under `skills/`:

```
skills/
  inspect-rock.md                # Skill prompt
  generate-documentation.md      # Skill prompt
  scripts/
    inspect-rock.sh              # Shell implementation
    generate-documentation.sh    # Shell implementation
```

**Files moved**: `inspect-rock.sh`, `generate-documentation.sh` from `.github/scripts/` to `skills/scripts/`. The `.github/scripts/` directory was removed.

**References updated** (16 total across 8 files):
- `skills/inspect-rock.md`, `skills/generate-documentation.md` — script paths
- `AGENTS.md` — repo layout + standalone documentation workflow
- `.github/workflows/agent-maintain.yml` — generate-documentation step
- `specs/001-helm-architect-agent/plan.md` — directory tree + structure decision
- `specs/001-helm-architect-agent/quickstart.md` — directory tree
- `specs/001-helm-architect-agent/contracts/skill-api.md` — script paths + examples
- `README.md` — skill file references

---

## Session: nginx Helm Chart Generation (Zero-to-One Mode)

**Date**: 2026-05-13  
**Trigger**: `create-chart.prompt.md` — nginx, rock image `ubuntu/nginx:1.28-26.04_edge`

### Steps

1. **inspect-rock**: Failed with exit 1 — neither docker nor podman is installed in the container environment. Proceeded with fallback HTTP probes on `GET /` port 80 (standard nginx behaviour).

2. **helm-toolkit (generator)**: Fetched `generate_chart_structure.sh` from `pantheon-org/tekhne`. Scaffolded `charts/nginx/` with `--image docker.io/ubuntu/nginx --tag 1.28-26.04_edge --port 80 --type deployment --with-templates`.

3. **Canonical overrides applied**:
   - `image.digest: ""` added to `values.yaml`
   - Deployment image reference wired with `{{- if .Values.image.digest }}@{{ .Values.image.digest }}{{- end }}`
   - Container `securityContext` updated to full PSS-Restricted: `runAsNonRoot`, `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`, `capabilities.drop: [ALL]`, `seccompProfile.type: RuntimeDefault`
   - `service.targetPort` corrected to 80 (nginx listens on 80)
   - Probes set to `httpGet path: /` (nginx default root)

4. **Helm test pod** created at `templates/tests/test-connection.yaml` with PSS-Restricted security context.

5. **Validation** (helm-validator workflow):
   - Stage 2 (structure): ✅ All required files present
   - Stage 3 (helm lint --strict): ✅ 0 errors (INFO: icon recommended)
   - Stage 4 (helm template render): ✅ 3 resources rendered
   - Stage 7 (kubeconform k8s 1.28): ✅ 3/3 valid
   - Stage 9 (security checks): ✅ All PSS-Restricted controls verified

6. **generate-documentation**: `charts/nginx/README.md` written with full values table.

### Decisions

- **inspect-rock fallback**: No container runtime available; used `httpGet /` probes since nginx defaults are well-known.
- **Port**: 80 — standard nginx HTTP port.
- **Image repository**: `docker.io/ubuntu/nginx` — full registry path per AGENTS.md requirement.
