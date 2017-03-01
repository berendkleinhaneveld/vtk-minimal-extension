#!/bin/bash -e

BUILD_CONFIG=Release

# use globs to take into account various possble suffixes: m, u, d
PY_LIB=`ls ${PREFIX}/lib/libpython${PY_VER}* | head -n 1`
PY_INC=`ls -d ${PREFIX}/include/python${PY_VER}* | head -n 1`

mkdir build
cd build

cmake ../. \
    -Wno-dev \
    -DCMAKE_BUILD_TYPE=${BUILD_CONFIG} \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_INSTALL_RPATH:STRING="${PREFIX}/lib" \
    -DPYTHON_INCLUDE_DIR:PATH=${PY_INC} \
    -DPYTHON_LIBRARY:FILEPATH=${PY_LIB} \
    ${MACOSX_DEPLOYMENT_TARGET:+-DCMAKE_OSX_DEPLOYMENT_TARGET='10.9'} \
    -DSP_DIR=${SP_DIR}

make -j${CPU_COUNT}
make install
