#!/bin/bash
set -e

# Simple installation script for llvm/clang.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLANG_SRC="$SCRIPT_DIR/src/clang-3.7.0.tar.xz"
COMPILER_RT_PATCH="$SCRIPT_DIR/src/clang_darwin.mk.patch"
CLANG_PATCH="$SCRIPT_DIR/src/AttrDump.inc.patch"
CLANG_PREFIX="$SCRIPT_DIR"

platform=`uname`

if [ $platform == 'Darwin' ]; then
    CONFIGURE_ARGS=(
        --prefix="$CLANG_PREFIX"
        --enable-libcpp
        --enable-cxx11
        --disable-assertions
        --enable-optimized
        --enable-bindings=none
    )
elif [ $platform == 'Linux' ]; then
    CONFIGURE_ARGS=(
        --prefix="$CLANG_PREFIX"
        --enable-cxx11
        --disable-assertions
        --enable-optimized
        --enable-bindings=none
    )
else
    echo "Clang setup: platform $platform is currently not supported by this script"; exit 1
fi

# start the installation
echo "Installing clang..."
TMP=`mktemp -d /tmp/clang-setup.XXXXXX`
pushd "$TMP"
tar xf "$CLANG_SRC"
# apply patch to compile on Darwin
pushd llvm/projects/compiler-rt
patch -p0 -i "$COMPILER_RT_PATCH"
popd
llvm/configure "${CONFIGURE_ARGS[@]}"

make -j 8 && make install
cp Release/bin/clang "$CLANG_PREFIX/bin/clang"
strip -x "$CLANG_PREFIX/bin/clang"
popd

# AttrDump.inc is autogenerated file so we can't patch it in clang source
pushd $CLANG_PREFIX
patch -p0 -i "$CLANG_PATCH"
popd

rm -rf "$TMP"
