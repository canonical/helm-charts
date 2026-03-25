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

	uv venv
	uv pip install pre-commit
	.venv/bin/pre-commit install
