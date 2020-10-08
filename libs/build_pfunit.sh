#!/bin/bash

set -eux

name="pfunit"
repo=${1:-${STACK_pfunit_repo:-"Goddard-Fortran-Ecosystem"}}
version=${2:-${STACK_pfunit_version:-"v1.4.2"}}

id=$repo-${version//\//.}

if $MODULES; then
  set +x
  source $MODULESHOME/init/bash
  module load hpc-$HPC_COMPILER
  module load hpc-$HPC_MPI
  module try-load cmake
  module list
  set -x

  prefix="${PREFIX:-"/opt/modules"}/${HPC_COMPILER//\//-}/${HPC_MPI//\//-}/$name/$id"
  if [[ -d $prefix ]]; then
    [[ $OVERWRITE =~ [yYtT] ]] && ( echo "WARNING: $prefix EXISTS: OVERWRITING!"; $SUDO rm -rf $prefix; $SUDO mkdir $prefix ) \
                               || ( echo "WARNING: $prefix EXISTS, SKIPPING"; exit 1 )
  fi
else
  prefix=${PFUNIT_ROOT:-"/usr/local"}
fi

software=$name-$repo-$id
cd ${HPC_STACK_ROOT}/${PKGDIR:-"pkg"}
[[ -d $software ]] || git clone -b $version https://github.com/$repo/$name.git $software
[[ -d $software ]] && cd $software || ( echo "$software does not exist, ABORT!"; exit 1 )

[[ ${DOWNLOAD_ONLY} =~ [yYtT] ]] && exit 0
[[ -d build ]] && $SUDO rm -rf build
mkdir -p build && cd build

#cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH ..
cmake -DCMAKE_INSTALL_PREFIX=$prefix ..
VERBOSE=$MAKE_VERBOSE make -j${NTHREADS:-4} install

# generate modulefile from template
$MODULES && update_modules mpi $name $id \
         || echo $name $id >> ${HPC_STACK_ROOT}/hpc-stack-contents.log
