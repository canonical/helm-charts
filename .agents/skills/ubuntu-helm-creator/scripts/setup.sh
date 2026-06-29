#!/bin/bash
# Setup development dependencies.
# Pass --install to auto-install missing tools.

set -e

INSTALL=
for arg in "$@"; do
	[ "$arg" = "--install" ] && INSTALL=1
done

MISSING_TOOLS=()
OPTIONAL_TOOLS=()

# rockcraft (required — provides skopeo)
if ! command -v rockcraft &> /dev/null; then
	if [ -n "$INSTALL" ]; then
		echo "installing rockcraft..."
		sudo snap install rockcraft --classic
	else
		MISSING_TOOLS+=("rockcraft")
	fi
else
	echo "rockcraft $(rockcraft --version)"
fi

# jq (required)
if ! command -v jq &> /dev/null; then
	if [ -n "$INSTALL" ]; then
		echo "installing jq..."
		sudo apt-get install -y jq
	else
		MISSING_TOOLS+=("jq")
	fi
else
	echo "jq $(jq --version)"
fi

# docker (optional — needed for filesystem inspection and Pebble plan)
if ! command -v docker &> /dev/null; then
	OPTIONAL_TOOLS+=("docker")
else
	echo "docker $(docker --version)"
fi

# Summary
if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
	echo
	echo "missing required tools: ${MISSING_TOOLS[*]}"
	echo "re-run as: $0 --install"
	echo
	for tool in "${MISSING_TOOLS[@]}"; do
		case $tool in
			rockcraft)
				echo "  rockcraft: sudo snap install rockcraft --classic"
				;;
			jq)
				echo "  jq:        sudo apt-get install jq"
				;;
		esac
	done
	exit 1
fi

if [ ${#OPTIONAL_TOOLS[@]} -gt 0 ]; then
	echo
	echo "optional tools not installed: ${OPTIONAL_TOOLS[*]}"
fi
