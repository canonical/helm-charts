set export
set shell := ["bash", "-c"]
set positional-arguments

[private]
default:
	@just --list

# Install development dependencies
setup:
	#!/bin/bash
	./skills/ubuntu-helm-creator/scripts/setup.sh --install
	./skills/ubuntu-helm-validator/scripts/setup.sh --install
	
	uv pip install pre-commit
	.venv/bin/pre-commit install

# Find a rock
find-rock image:
	./skills/ubuntu-helm-creator/scripts/inspect-rock.sh inspect $1

# Get a rock's entrypoint
get-rock-entrypoint image:
	./skills/ubuntu-helm-creator/scripts/inspect-rock.sh entrypoint $1

# Inspect a rock's filesystem with dive (JSON output)
get-rock-filesystem image:
	./skills/ubuntu-helm-creator/scripts/inspect-rock.sh filesystem $1

# Get a rock's metadata (labels)
get-rock-metadata image:
	./skills/ubuntu-helm-creator/scripts/inspect-rock.sh metadata $1

# Lint a Helm chart
lint chart:
	./skills/ubuntu-helm-validator/scripts/run-test.sh lint charts/{{chart}}

# Render Helm templates and optionally validate with kubectl
render-templates chart:
	./skills/ubuntu-helm-validator/scripts/run-test.sh render-templates charts/{{chart}}

# Test rendered templates against OPA policies
test-policies chart:
	./skills/ubuntu-helm-validator/scripts/run-test.sh test-policies charts/{{chart}}

# Run Helm unittest tests
unit-test chart:
	./skills/ubuntu-helm-validator/scripts/run-test.sh unit-test charts/{{chart}}

# Run integration tests with spread (requires Spread)
integration-test chart:
	@echo "Running integration tests for chart {{chart}}..."
	spread charts/{{chart}}

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
