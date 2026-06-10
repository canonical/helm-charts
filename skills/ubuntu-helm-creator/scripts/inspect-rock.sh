#!/bin/bash
set -e

usage() {
	cat >&2 <<-EOF
		Usage: $0 <operation> <image>

		Operations:
		  inspect      Full skopeo inspect of the image
		  entrypoint   Print the OCI entrypoint (JSON array)
		  filesystem   List all files across image layers
		  metadata     Print OCI labels / annotations
		  digest       Print the image digest (sha256:...)
	EOF
	exit 1
}

[ $# -lt 2 ] && usage

OP=$1
IMAGE=$2

case "$OP" in
inspect)
	echo "Inspecting rock $IMAGE..."
	rockcraft.skopeo inspect docker://"$IMAGE"
	;;

entrypoint)
	rockcraft.skopeo inspect --config docker://"$IMAGE" \
		--format '{{ json .Config.Entrypoint }}'
	;;

filesystem)
	docker run --rm \
		-v /var/run/docker.sock:/var/run/docker.sock:ro \
		--entrypoint sh \
		wagoodman/dive:v0.13.1 \
		-c "dive --json out.json $IMAGE >/dev/null && cat out.json" |
		jq -r '.layer[] | .fileList[]'
	;;

metadata)
	rockcraft.skopeo inspect --config docker://"$IMAGE" \
		--format '{{ json .Config.Labels }}'
	;;

digest)
	rockcraft.skopeo inspect docker://"$IMAGE" \
		--format '{{ .Digest }}'
	;;

*)
	echo "Unknown operation: $OP" >&2
	usage
	;;
esac
