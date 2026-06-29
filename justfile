set export
set shell := ["bash", "-c"]
set positional-arguments

[private]
default:
	@just --list

# Install development dependencies
setup:
	#!/bin/bash
	./.agents/skills/ubuntu-helm-creator/scripts/setup.sh --install
	./.agents/skills/ubuntu-helm-validator/scripts/setup.sh --install
	
	uv pip install pre-commit
	.venv/bin/pre-commit install

# Find a rock
find-rock image:
	./.agents/skills/ubuntu-helm-creator/scripts/inspect-rock.sh inspect $1

# Get a rock's entrypoint
get-rock-entrypoint image:
	./.agents/skills/ubuntu-helm-creator/scripts/inspect-rock.sh entrypoint $1

# Inspect a rock's filesystem with dive (JSON output)
get-rock-filesystem image:
	./.agents/skills/ubuntu-helm-creator/scripts/inspect-rock.sh filesystem $1

# Get a rock's metadata (labels)
get-rock-metadata image:
	./.agents/skills/ubuntu-helm-creator/scripts/inspect-rock.sh metadata $1

# Lint a Helm chart
lint chart:
	./.agents/skills/ubuntu-helm-validator/scripts/run-test.sh lint charts/{{chart}}

# Render Helm templates and optionally validate with kubectl
render-templates chart:
	./.agents/skills/ubuntu-helm-validator/scripts/run-test.sh render-templates charts/{{chart}}

# Test rendered templates against OPA policies
test-policies chart:
	./.agents/skills/ubuntu-helm-validator/scripts/run-test.sh test-policies charts/{{chart}}

# Run Helm unittest tests
unit-test chart:
	./.agents/skills/ubuntu-helm-validator/scripts/run-test.sh unit-test charts/{{chart}}

integration-test chart:
	./.agents/skills/ubuntu-helm-validator/scripts/run-test.sh integration-test charts/{{chart}}

# Run all tests for a chart
test chart:
	#!/bin/bash
	
	ret=0
	for action in lint render-templates test-policies unit-test integration-test
	do
		just $action {{chart}} || ret=$?
	done

	exit $ret

# Run all tests for all charts
test-all:
	#!/bin/bash

	ret=0
	for chart in $(ls charts); do
		echo "Testing chart: $chart"
		just test $chart || ret=$?
	done

	exit $ret
