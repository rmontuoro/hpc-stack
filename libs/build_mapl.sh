#!/bin/bash

set -eux

name="mapl"
repo=${1:-${STACK_mapl_repo:-"GEOS-ESM"}}
version=${2:-${STACK_mapl_version:-"NUOPC_MAPLcap"}}

# Hyphenated version used for install prefix
compiler=$(echo $HPC_COMPILER | sed 's/\//-/g')
mpi=$(echo $HPC_MPI | sed 's/\//-/g')
id=${version//\//-}

if $MODULES; then
  set +x
  source $MODULESHOME/init/bash
  module try-load cmake
  module load hpc-$HPC_COMPILER
  module load hpc-$HPC_MPI
  module load ecbuild
  module load gftl-shared
  module load flap
  module load pflogger
  module load pfunit
  module load yafyaml
  module load esma_cmake
  module load cmakemodules
  module load python
  module list
# export CMAKE_MODULE_PATH="/work/noaa/nems/rmontuor/dev/app/repo/install/core/ecbuild/GEOS-ESM-geos.v1.0.5/share/ecbuild/cmake/;${CMAKE_MODULE_PATH}"
# export CMAKE_PREFIX_PATH="/work/noaa/nems/rmontuor/dev/app/repo/install/core/ecbuild/GEOS-ESM-geos.v1.0.5/lib/cmake/ecbuild;${CMAKE_PREFIX_PATH}"
echo "MAPL - module listed"
  set -x

  prefix="${PREFIX:-"/opt/modules"}/$compiler/$mpi/$name/$repo-$id"
  if [[ -d $prefix ]]; then
    [[ $OVERWRITE =~ [yYtT] ]] && ( echo "WARNING: $prefix EXISTS: OVERWRITING!"; $SUDO rm -rf $prefix ) \
                               || ( echo "WARNING: $prefix EXISTS, SKIPPING"; exit 1 )
  fi
else
  prefix=${MAPL_ROOT:-"/usr/local"}
fi

#export FC=$MPI_FC
#export CC=$MPI_CC

#export CFLAGS="${STACK_CFLAGS:-} ${STACK_mapl_CFLAGS:-} -fPIC -w"
#export FFLAGS="${STACK_FFLAGS:-} ${STACK_mapl_FFLAGS:-} -fPIC -w"
#export FCFLAGS="${FFLAGS}"

software=$name-$repo-$id
cd ${HPC_STACK_ROOT}/${PKGDIR:-"pkg"}
[[ -d $software ]] || git clone -b $version https://github.com/$repo/$name.git $software
[[ -d $software ]] && cd $software || ( echo "$software does not exist, ABORT!"; exit 1 )

[[ ${DOWNLOAD_ONLY} =~ [yYtT] ]] && exit 0
[[ -d build ]] && $SUDO rm -rf build
mkdir -p build && cd build

CMAKE_OPTS=${STACK_mapl_cmake_opts:-""}

cmake .. \
      -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_MODULE_PATH=$CMAKE_MODULE_PATH \
      -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH \
      -DCMAKE_BUILD_TYPE=Release \
      ${CMAKE_OPTS}

VERBOSE=$MAKE_VERBOSE make -j${NTHREADS:-4} install

# generate modulefile from template
$MODULES && update_modules mpi $name $repo-$id \
         || echo $name $repo-$id >> ${HPC_STACK_ROOT}/hpc-stack-contents.log
