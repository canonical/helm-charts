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

# Lint a Helm chart
lint chart:
	@echo "Linting $1..."
	@helm lint $1

# Lint all charts
lint-all:
	@for chart in charts/*; do \
		if [ -d "$chart" ]; then \
			echo "Linting $chart..."; \
			just lint $chart; \
		fi; \
	done

# Run tests for a Helm chart
test chart:
	#!/bin/bash
	
	# Lint 
	just lint $1
