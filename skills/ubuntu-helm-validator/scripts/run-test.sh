#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"

# Lint a Helm chart
lint() {
	local chart="$1"
	echo "Linting Helm chart ${chart}..."
	helm lint "${REPO_ROOT}/${chart}"
}

# Render Helm templates and optionally validate with kubectl
render-templates() {
	local chart="$1"
	local name
	name="$(basename "$chart")"
	echo "Rendering Helm templates for chart ${chart}..."
	if command -v kubectl &> /dev/null; then
		helm template "test-templates-${name}" "${REPO_ROOT}/${chart}" | kubectl apply --dry-run=client -f -
	else
		helm template "test-templates-${name}" "${REPO_ROOT}/${chart}" > /dev/null
	fi
}

# Test rendered templates against OPA policies
test-policies() {
	local chart="$1"
	local container_image="openpolicyagent/conftest@sha256:5fd81e332d7e4bc01daf3ef35371800a9a9720a30c0c37a78de0c5fbe4b6d622"
	local name
	name="$(basename "$chart")"

	if ! command -v docker &> /dev/null; then
		echo "Error: docker is required to run OPA policy tests (conftest)." >&2
		exit 1
	fi

	local container_run_args=(--rm -i -v "${REPO_ROOT}:/project")

	echo "Testing policies for chart ${chart}..."
	helm template "test-templates-${name}" "${REPO_ROOT}/${chart}" | \
		docker run "${container_run_args[@]}" \
			"${container_image}" \
			test - --policy /project/policy.rego

	if [ -f "${REPO_ROOT}/${chart}/policy.rego" ]; then
		echo "Testing chart-specific policies for chart ${chart}..."
		helm template "test-templates-${name}" "${REPO_ROOT}/${chart}" | \
			docker run "${container_run_args[@]}" \
				"${container_image}" \
				test - --policy "/project/${chart}/policy.rego"
	fi
}

# Run Helm unittest tests
unit-test() {
	local chart="$1"
	echo "Running Helm unittest for chart ${chart}..."
	helm unittest "${REPO_ROOT}/${chart}"
}

# Run integration tests with spread (requires Spread)
integration-test() {
	local chart="$1"
	echo "Running integration tests for chart ${chart}..."

	if ! command -v spread &> /dev/null; then
		echo "spread not installed; skipping integration tests." >&2
		return 0
	fi
	if [ ! -f "${REPO_ROOT}/spread.yaml" ]; then
		echo "spread.yaml not found at repo root; skipping integration tests." >&2
		return 0
	fi
	if [ ! -f "${REPO_ROOT}/${chart}/task.yaml" ]; then
		echo "No task.yaml found for ${chart}; skipping integration tests." >&2
		return 0
	fi

	(cd "${REPO_ROOT}" && spread "${chart}")
}

usage() {
	echo "Usage: $(basename "$0") <command> <chart>"
	echo ""
	echo "Commands:"
	echo "  lint              Lint a Helm chart"
	echo "  render-templates  Render templates and optionally validate with kubectl"
	echo "  test-policies     Test rendered templates against OPA policies"
	echo "  unit-test         Run Helm unittest tests"
	echo "  integration-test  Run integration tests with spread"
}

if [[ $# -lt 2 ]]; then
	usage
	exit 1
fi

command="$1"
chart="$2"

case "$command" in
	lint|render-templates|test-policies|unit-test|integration-test)
		"$command" "$chart"
		;;
	*)
		echo "Error: unknown command '${command}'" >&2
		usage
		exit 1
		;;
esac
