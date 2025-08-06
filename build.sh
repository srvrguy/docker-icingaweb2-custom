#!/bin/bash
# Based on the Icinga 2 Docker image build.bash
# Icinga 2 Docker image | (c) 2020 Icinga GmbH | GPLv2+
set -euxo pipefail

# Default values for variables
ACTION="" # Stores a flag for either "push" or "load". If blank, it just does a plain build.
TAG=latest

usage() {
	echo "Usage: ${0} [-t TAG] [-a <push|load>]"
	exit 1
}

if [[ -z "${REPO_OWNER+isset}" ]]; then
    echo "Environment variable REPO_OWNER is not set. This should be set by the build system automatically." >&2
	echo "If you are running this manually, set it before running." >&2
    exit 1
fi

while getopts ":ha:t:" opt; do
	case ${opt} in
		a)
			case "${OPTARG}" in
				push)
					ACTION="--push";;
				load)
					ACTION="--load";;
				*)
					echo "Invalid action: ${OPTARG}" 1>&2; usage;;
			esac;;
		t)
			TAG="${OPTARG}"
			;;
		:)
			echo "Invalid option: -${OPTARG} requires an argument" 1>&2; usage;
			;;
		\?)
			echo "Invalid option: -${OPTARG}" 1>&2; usage;
			;;
		*)
			usage
			;;
		esac
done

DEBUG_TAG="${TAG}-debug"

echo "Action is ${ACTION}"
echo "Tag is ${TAG}"
echo "Debug tag is ${DEBUG_TAG}"

# Check for either nerdctl or docker commands to use for building images
if command -v nerdctl; then
    BUILDTOOL=nerdctl
elif command -v docker &> /dev/null && docker buildx version &> /dev/null; then
    BUILDTOOL="docker buildx"
else
	echo "Cannot proceed. Neither nerdctl nor docker buildx are available." >&2
    exit 1
fi

echo "Build tool selected: ${BUILDTOOL}"

PLATFORMS="$(cat platforms.txt)"


# Some variables used in building things below
WORKING_DIR="$(realpath "$(dirname "$0")")"
RELEASE_ARGS=(--no-cache --target release --tag "ghcr.io/$REPO_OWNER/icingaweb2-custom:$TAG" $WORKING_DIR)
DEBUG_ARGS=(--no-cache --target debug --tag "ghcr.io/$REPO_OWNER/icingaweb2-custom:$DEBUG_TAG" $WORKING_DIR)

# Build both the "release" and "debug" images
${BUILDTOOL} build ${ACTION} --platform ${PLATFORMS} ${RELEASE_ARGS[@]}
${BUILDTOOL} build ${ACTION} --platform ${PLATFORMS} ${DEBUG_ARGS[@]}
