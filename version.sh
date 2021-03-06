#!/bin/bash
# Copyright (C) 2018, Patrik Dufresne Service Logiciel inc.
# Use is subject to license terms.
#
# This script return a valid maven version from git SCM. This  implementation 
# is inspired from python scm_version.
#
# no distance and clean:
#   {tag}
# distance and clean:
#   {next_version}-{distance}-g{revision hash}
# no distance and not clean:
#   {tag}-dYYMMDD
# distance and not clean:
#   {next_version}-{distance}-g{revision hash}.dYYMMDD
#
set -e
increment_version ()
{
    declare -a part=( ${VERSION//[^0-9]/ } )
    declare -a sep=( ${VERSION//[0-9]/ } )
    declare -i carry=1
    declare    new
    for (( CNTR=${#part[@]}-1; CNTR>=0; CNTR-=1 )); do
        len=${#part[CNTR]}
        new=$((part[CNTR]+carry))
        [ ${#new} -gt $len ] && carry=1 || carry=0
        [ $CNTR -gt 0 ] && part[CNTR]=${new: -len} || part[CNTR]=${new}
    done
    declare final
    for (( CNTR=0; CNTR<=${#part[@]}-1; CNTR+=1 )); do
        final="$final${part[CNTR]}${sep[CNTR]}"
    done
    echo -e "$final"
}
if ! type git > /dev/null; then
    echo "git executable can't be found!"
    exit 1
fi
DESCRIBE=$(git describe --dirty --tags --long --match "*.*" 2>/dev/null || true)
if [ -z "$DESCRIBE" ]; then
	TAG="0.0.0"
	DISTANCE="$(git rev-list HEAD 2>/dev/null | wc -l)"
	DIRTY=1
	if [ -z "$(git status --porcelain --untracked-files=no)" ]; then
		DIRTY=0
	fi
	NODE="$(git rev-parse --verify --quiet HEAD | cut -c 1-7)"
else
	# garbage-v3.0.6-24-g2c76283-dirty
	DIRTY=0
	if [[ "$DESCRIBE" == *-dirty ]]; then
	  DIRTY=1
	  DESCRIBE="${DESCRIBE/-dirty/}"
	fi
	# garbage-v3.0.6-24-g2c76283
	NODE="${DESCRIBE##*-g}"
	DESCRIBE=${DESCRIBE%-g*}
	# garbage-v3.0.6-24
	DISTANCE="${DESCRIBE##*-}"
	# garbage-v3.0.6
	TAG="${DESCRIBE%-*}"
fi
TIMESTAMP=$(date '+%Y%m%d')
# Strip tag to get version
# Remove leading "garbage-v"
# Remove trailing "-g2c76283"
VERSION="${TAG%%-d*}"
VERSION="${VERSION%%-g*}"
VERSION="${VERSION%%+*}"
VERSION="${VERSION##*-}"
VERSION="${VERSION##v}"
NEXT_VERSION=$(increment_version "$VERSION")
# Print version
if [ -z "$NODE" ]; then
	# {next_version}-{distance}
	printf "%s-%s\n" "$NEXT_VERSION" "$DISTANCE"
elif [ $DISTANCE -eq 0 -a $DIRTY -eq 0 ]; then
	# {tag}
	printf "%s\n" "$VERSION"
elif [ $DISTANCE -ne 0 -a $DIRTY -eq 0 ]; then
	# {next_version}-{distance}-g{revision hash}
	printf "%s-%s-g%s\n" "$NEXT_VERSION" "$DISTANCE" "$NODE"
elif [ $DISTANCE -eq 0 -a $DIRTY -ne 0 ]; then
	# {tag}-dYYMMDD
	printf "%s-d%s\n" "$VERSION" "$TIMESTAMP"
else
	# {next_version}-{distance}-g{revision hash}.dYYMMDD
	printf "%s-%s-g%s-d%s\n" "$NEXT_VERSION" "$DISTANCE" "$NODE" "$TIMESTAMP"
fi

