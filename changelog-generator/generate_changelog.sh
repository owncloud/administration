#!/bin/bash

source config.sh

# TODO: make these CLI params
START_TAG=v9.0.3
END_TAG=v9.0.4RC1
#BRANCH=stable9

if test -z "$GENERATOR_BIN" -o -z "$USERNAME"; then
	echo "Invalid configuration" >&2
	exit 1
fi

if test -z "$TOKEN"; then
	echo "Missing TOKEN in config.sh, please generate one in your Github settings" >&2
	exit 1
fi

if ! test -x "$GENERATOR_BIN"; then
	echo "Cannot find generator executable in path \"$GENERATOR_BIN\", please check config.sh" >&2
	exit 1
fi

#PARAMS="--no-author --no-unreleased"
PARAMS="--no-author"

if test "$START_TAG" -a "$END_TAG"; then
	PARAMS="$PARAMS --between-tags ${START_TAG},${END_TAG}"
else
	if test "$START_TAG"; then
		PARAMS="$PARAMS --since-tag $START_TAG"
	fi

	if test "$END_TAG"; then
		PARAMS="$PARAMS --due-tag $END_TAG"
	fi
fi

if test "$BRANCH"; then
	PARAMS="$PARAMS --release-branch $BRANCH"
fi

for REPO in $REPOSITORIES; do
	$GENERATOR_BIN -u "$USERNAME" -t "$TOKEN" e -p "$REPO" $PARAMS -o "changelog-${START_TAG}-${END_TAG}.md"
done

