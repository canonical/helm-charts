set export
set shell := ["bash", "-c"]
set positional-arguments

[private]
default:
	@just --list

# Install development dependencies
setup:
	#!/bin/bash
	INSTALL=1 ./skills/ubuntu-helm-creator/scripts/setup.sh
	
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

lint chart:
	@echo "Linting Helm chart {{chart}}..."
	helm lint charts/{{chart}}

render-templates chart:
	#!/bin/bash
	echo "Rendering Helm templates for chart {{chart}}..."
	if command -v kubectl &> /dev/null; then
		helm template test-templates-{{chart}} charts/{{chart}} | kubectl apply --dry-run=client -f -
	else
		helm template test-templates-{{chart}} charts/{{chart}} > /dev/null
	fi

test-policies chart:
	@echo "Testing policies for chart {{chart}}..."
	helm template test-templates-{{chart}} charts/{{chart}} | \
	docker run --rm -i -v $(git rev-parse --show-toplevel):/project \
		openpolicyagent/conftest@sha256:5fd81e332d7e4bc01daf3ef35371800a9a9720a30c0c37a78de0c5fbe4b6d622 \
		test - --policy /project/policy.rego

unit-test chart:
	@echo "Running Helm unittest for chart {{chart}}..."
	helm unittest charts/{{chart}}

integration-test chart:
	@echo "Running integration tests for chart {{chart}}..."
	spread charts/{{chart}}

test chart:
	#!/bin/bash
	
	ret=0
	for action in lint render-templates test-policies unit-test #integration-test
	do
		just $action {{chart}} || ret=$?
	done

	exit $ret

test-all:
	#!/bin/bash

	ret=0
	for chart in $(ls charts); do
		echo "Testing chart: $chart"
		just test $chart || ret=$?
	done

	exit $ret
