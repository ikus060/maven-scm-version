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
# First arguments, define the format styled to be used.
# * DEFAULT: {next_version}-{distance}-g{revision hash}
# * DEB:     {next_version}~dev{distance}+g{revision hash}
#

set -e
increment_version ()
{
  declare    base=( ${1%%[0-9]} )
  declare -a part=( ${1//[^0-9]/ } )
  echo "${base}$((${part[-1]}+1))"
}
if ! type git > /dev/null; then
    echo "git executable can't be found!"
    exit 1
fi
case "$1" in
DEB|DEBIAN)
  SEP1="~dev"
  SEP2="+g"
  SEP3="+d"
  ;;
*)
  SEP1="-"
  SEP2="-g"
  SEP3=".d"
  ;;
esac

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
VERSION="${VERSION##V}"
NEXT_VERSION=$(increment_version "$VERSION")
# Print version
if [ -z "$NODE" ]; then
    # {next_version}-{distance}
    printf "%s%s%s\n" "$NEXT_VERSION" "$SEP1" "$DISTANCE"
elif [ $DISTANCE -eq 0 -a $DIRTY -eq 0 ]; then
    # {tag}
    printf "%s\n" "$VERSION"
elif [ $DISTANCE -ne 0 -a $DIRTY -eq 0 ]; then
    # {next_version}-{distance}-g{revision hash}
    printf "%s%s%s%s%s\n" "$NEXT_VERSION" "$SEP1" "$DISTANCE" "$SEP2" "$NODE"
elif [ $DISTANCE -eq 0 -a $DIRTY -ne 0 ]; then
    # {tag}-dYYMMDD
    printf "%s%s%s\n" "$VERSION" "$SEP3" "$TIMESTAMP"
else
    # {next_version}-{distance}-g{revision hash}.dYYMMDD
    printf "%s%s%s%s%s%s%s\n" "$NEXT_VERSION" "$SEP1" "$DISTANCE" "$SEP2" "$NODE" "$SEP3" "$TIMESTAMP"
fi