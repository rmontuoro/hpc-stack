#!/bin/bash

set -eux

name="gftl-shared"
repo=${1:-${STACK_gftl_shared_repo:-"Goddard-Fortran-Ecosystem"}}
version=${2:-${STACK_gftl_shared_version:-"main"}}

if $MODULES; then
  set +x
  source $MODULESHOME/init/bash
  module try-load cmake
  module load hpc-$HPC_COMPILER
  module list
  set -x

  prefix="${PREFIX:-"/opt/modules"}/${HPC_COMPILER//\//-}/$name/$repo-$version"
  if [[ -d $prefix ]]; then
    [[ $OVERWRITE =~ [yYtT] ]] && ( echo "WARNING: $prefix EXISTS: OVERWRITING!"; $SUDO rm -rf $prefix; $SUDO mkdir $prefix ) \
                               || ( echo "WARNING: $prefix EXISTS, SKIPPING"; exit 1 )
  fi
else
  prefix=${GFTL_SHARED_ROOT:-"/usr/local"}
fi

software=$name-$repo-$version
cd ${HPC_STACK_ROOT}/${PKGDIR:-"pkg"}
[[ -d $software ]] || git clone -b $version https://github.com/$repo/$name.git $software
[[ -d $software ]] && cd $software || ( echo "$software does not exist, ABORT!"; exit 1 )

[[ ${DOWNLOAD_ONLY} =~ [yYtT] ]] && exit 0
[[ -d build ]] && $SUDO rm -rf build
mkdir -p build && cd build

cmake -DCMAKE_INSTALL_PREFIX=$prefix ..
VERBOSE=$MAKE_VERBOSE make -j${NTHREADS:-4} install

# generate modulefile from template
$MODULES && update_modules compiler $name $repo-$version \
         || echo $name $repo-$version >> ${HPC_STACK_ROOT}/hpc-stack-contents.log
