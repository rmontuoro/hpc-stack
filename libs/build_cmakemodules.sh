#!/bin/bash

set -eux

name="cmakemodules"
repo=${1:-${STACK_cmakemodules_repo:-"NOAA-EMC"}}
version=${2:-${STACK_cmakemodules_version:-"develop"}}
id=${version//\//-}

if $MODULES; then
  set +x
  source $MODULESHOME/init/bash
  module list
  set -x

  prefix="${PREFIX:-"/opt/modules"}/core/$name/$repo-$id"
  if [[ -d $prefix ]]; then
    [[ $OVERWRITE =~ [yYtT] ]] && ( echo "WARNING: $prefix EXISTS: OVERWRITING!"; $SUDO rm -rf $prefix; $SUDO mkdir $prefix ) \
                               || ( echo "WARNING: $prefix EXISTS, SKIPPING"; exit 1 )
  fi
else
  prefix=${CMAKEMODULES_ROOT:-"/usr/local"}
fi

software=$name-$repo-$id
cd ${HPC_STACK_ROOT}/${PKGDIR:-"pkg"}
[[ -d $software ]] || git clone https://github.com/$repo/$name.git $software
[[ -d $software ]] && cd $software || ( echo "$software does not exist, ABORT!"; exit 1 )
git fetch --tags
git checkout $version
[[ ${DOWNLOAD_ONLY} =~ [yYtT] ]] && exit 0

cd ${HPC_STACK_ROOT}/${PKGDIR:-"pkg"}
mkdir -p $prefix && cp -r $software/* $prefix
# generate modulefile from template
$MODULES && update_modules core $name $repo-$id \
         || echo $name $repo-$id >> ${HPC_STACK_ROOT}/hpc-stack-contents.log
