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

# helm (required)
if ! command -v helm &> /dev/null; then
	if [ -n "$INSTALL" ]; then
		echo "installing helm..."
		sudo snap install helm --classic --stable
	else
		MISSING_TOOLS+=("helm")
	fi
else
	echo "helm $(helm version --short 2>/dev/null || helm version)"
fi

# helm plugins (installed only when INSTALL is set and helm is available)
if [ -n "$INSTALL" ] && command -v helm &> /dev/null; then
	if ! helm plugin list 2>/dev/null | grep -q "unittest"; then
		echo "installing helm-unittest plugin..."
		helm plugin install https://github.com/helm-unittest/helm-unittest --verify=false
	fi

	if ! helm plugin list 2>/dev/null | grep -q "diff"; then
		echo "installing helm-diff plugin..."
		helm plugin install https://github.com/databus23/helm-diff --verify=false
	fi
fi

# kubeconform (required)
if ! command -v kubeconform &> /dev/null; then
	if [ -n "$INSTALL" ]; then
		echo "installing kubeconform..."
		go install github.com/yannh/kubeconform/cmd/kubeconform@v0.6.7
	else
		MISSING_TOOLS+=("kubeconform")
	fi
else
	echo "kubeconform $(kubeconform -v)"
fi

# spread
if ! command -v spread &> /dev/null; then
	if [ -n "$INSTALL" ]; then
		echo "installing spread..."
		go install github.com/canonical/spread@main
	else
		OPTIONAL_TOOLS+=("spread")
	fi
else
	echo "spread $(spread --version)"
fi

# kind (optional — needed for cluster dry-run)
if ! command -v kind &> /dev/null; then
	if [ -n "$INSTALL" ]; then
		echo "installing kind..."
		go install sigs.k8s.io/kind@v0.32.0
	else
		OPTIONAL_TOOLS+=("kind")
	fi
else
	echo "kind $(kind --version)"
fi

# Python environment
if command -v uv &> /dev/null; then
	uv venv --clear
	uv pip install yamllint
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
				echo "  uv:          sudo snap install astral-uv --classic"
				echo "               curl -LsSf https://astral.sh/uv/install.sh | sh"
				;;
			helm)
				echo "  helm:        sudo snap install helm --classic"
				echo "               https://helm.sh/docs/intro/install/"
				;;
			kubeconform)
				echo "  kubeconform: go install github.com/yannh/kubeconform/cmd/kubeconform@v0.6.7"
				echo "               https://github.com/yannh/kubeconform/releases"
				;;
		esac
	done
	exit 1
fi

if [ ${#OPTIONAL_TOOLS[@]} -gt 0 ]; then
	echo
	echo "optional tools not installed: ${OPTIONAL_TOOLS[*]}"
	echo "re-run as: $0 --install"
fi
