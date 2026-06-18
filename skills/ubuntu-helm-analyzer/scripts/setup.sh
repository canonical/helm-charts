#!/bin/bash
# Setup development dependencies.
# Pass --install to auto-install missing tools.

set -e

INSTALL=
for arg in "$@"; do
	[ "$arg" = "--install" ] && INSTALL=1
done

MISSING_TOOLS=()

# helm (required)
if ! command -v helm &> /dev/null; then
	if [ -n "$INSTALL" ]; then
		echo "installing helm..."
		sudo snap install helm --classic
	else
		MISSING_TOOLS+=("helm")
	fi
else
	echo "helm $(helm version --short 2>/dev/null || helm version)"
fi

# git (required)
if ! command -v git &> /dev/null; then
	if [ -n "$INSTALL" ]; then
		echo "installing git..."
		sudo apt-get install -y git
	else
		MISSING_TOOLS+=("git")
	fi
else
	echo "git $(git --version)"
fi

# yq (required)
if ! command -v yq &> /dev/null; then
	if [ -n "$INSTALL" ]; then
		echo "installing yq..."
		sudo apt-get install -y yq
	else
		MISSING_TOOLS+=("yq")
	fi
else
	echo "yq $(yq --version)"
fi

# Summary
if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
	echo
	echo "missing required tools: ${MISSING_TOOLS[*]}"
	echo "re-run as: $0 --install"
	echo
	for tool in "${MISSING_TOOLS[@]}"; do
		case $tool in
			helm)
				echo "  helm: sudo snap install helm --classic"
				;;
			git)
				echo "  git:  sudo apt-get install -y git"
				;;
			yq)
				echo "  yq:   sudo apt-get install -y yq"
				;;
		esac
	done
	exit 1
fi
