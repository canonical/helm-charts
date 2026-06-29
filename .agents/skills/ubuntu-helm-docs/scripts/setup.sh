#!/bin/bash
# Setup development dependencies.
# Pass --install to auto-install missing tools.

set -e

INSTALL=
for arg in "$@"; do
	[ "$arg" = "--install" ] && INSTALL=1
done

MISSING_TOOLS=()

# uv (required)
if ! command -v uv &> /dev/null; then
	if [ -n "$INSTALL" ]; then
		echo "installing uv..."
		sudo snap install astral-uv --classic
	else
		MISSING_TOOLS+=("uv")
	fi
else
	echo "uv $(uv --version)"
fi

# Summary
if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
	echo
	echo "missing required tools: ${MISSING_TOOLS[*]}"
	echo "re-run as: $0 --install"
	echo
	for tool in "${MISSING_TOOLS[@]}"; do
		case $tool in
			uv)
				echo "  uv: sudo snap install astral-uv --classic"
				;;
		esac
	done
	exit 1
fi
