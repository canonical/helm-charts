set export
set shell := ["bash", "-c"]
set positional-arguments

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

	if ! command -v rockcraft &> /dev/null; then
	    echo "rockcraft not found. Installing rockcraft..."
	    sudo snap install rockcraft --classic
	else
	    echo "rockcraft is already installed."
	fi

	uv venv --clear
	# pyyaml is used by the AI skills

	uv pip install pre-commit pyyaml
	
	.venv/bin/pre-commit install

# Find a rock
find-rock image:
	#!/bin/bash
	echo "Looking up rock $1..."
	rockcraft.skopeo inspect \
		docker://$1

# Get a rock's entrypoint
get-rock-entrypoint image:
	@rockcraft.skopeo inspect --config \
		docker://$1 \
		--format '{{ "{{" }} json .Config.Entrypoint {{ "}}" }}'

# Inspect a rock's filesystem with dive (JSON output)
get-rock-filesystem image:
	#!/bin/bash
	docker run --rm \
		-v /var/run/docker.sock:/var/run/docker.sock:ro \
		--entrypoint sh \
		wagoodman/dive:v0.13.1 \
		-c "dive --json out.json $1 >/dev/null && cat out.json" \
			| jq -r '.layer[] | .fileList[]'

# Get a rock's metadata (labels)
get-rock-metadata image:
	@rockcraft.skopeo inspect --config \
		docker://$1 \
		--format '{{ "{{" }} json .Config.Labels {{ "}}" }}'
