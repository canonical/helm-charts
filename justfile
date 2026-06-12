set export
set shell := ["bash", "-c"]

[private]
default:
	@just --list

# Install development dependencies
setup:
	#!/bin/bash
	echo "Installing development dependencies..."
	if ! command -v uv &> /dev/null; then
	    echo "uv not found. Installing uv..."
	    sudo snap install astral-uv --classic
	else
	    echo "uv is already installed."
	fi

	if ! command -v helm &> /dev/null; then
	    echo "helm not found. Installing helm..."
	    sudo snap install helm --classic
	else
	    echo "helm is already installed."
	fi

	helm plugin list 2>/dev/null | grep -q unittest || helm plugin install https://github.com/helm-unittest/helm-unittest --verify=false

	uv venv
	uv pip install pre-commit
	.venv/bin/pre-commit install

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
