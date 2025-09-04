#!/bin/bash

. "$(dirname $0)/defines.sh";

cmake_root=$SOURCE_ROOT/android-tools/out;

# Clean built products
[[ -d "$cmake_root" ]] && rm -rfv "$cmake_root";
mkdir -pv "$cmake_root";

cd "$cmake_root" || exit;

# Init update android tools submodules
echo "→ Reset android tools and submodules";
$(cd "$SOURCE_ROOT/android-tools" && git checkout . && git submodule update --init --recursive);
for dep_repo in $(ls -d "$SOURCE_ROOT"/android-tools/vendor/*); do
  [[ -d "$dep_repo" ]] || continue;
  echo "→ Reset $dep_repo";
  $(cd "$dep_repo" && git checkout . && git am --abort);
done
echo "→ Update external submodules"
$(cd "$SOURCE_ROOT/android-tools" && git submodule update --init --recursive)

# Resolve SDK path for CMake
SDK_PATH=$(xcrun --sdk $SDK_NAME --show-sdk-path)

# Try to locate BoringSSL public include dir
BORINGSSL_INC=""
for path in \
  "$SOURCE_ROOT/android-tools/external/boringssl/src/include" \
  "$SOURCE_ROOT/android-tools/vendor/boringssl/src/include" \
  "$SOURCE_ROOT/android-tools/boringssl/src/include"; do
  if [[ -d "$path" ]]; then BORINGSSL_INC="$path"; break; fi
done
echo " - BoringSSL include: ${BORINGSSL_INC:-not found}"

# Provide a fallback openssl include path under vendor/core/include if found
mkdir -p "$SOURCE_ROOT/android-tools/vendor/core/include"
if [[ -n "$BORINGSSL_INC" ]]; then
  ln -snf "$BORINGSSL_INC/openssl" "$SOURCE_ROOT/android-tools/vendor/core/include/openssl"
else
  # Create an empty dir to satisfy include path; actual headers should be provided by boringssl submodule
  mkdir -p "$SOURCE_ROOT/android-tools/vendor/core/include/openssl"
fi

cmake -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TOOLCHAIN_FILE -DPLATFORM=$PLATFORM \
  -DCMAKE_OSX_SYSROOT="$SDK_PATH" -DCMAKE_OSX_ARCHITECTURES=$ARCH_NAME \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=$DEPLOYMENT_TARGET -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_C_FLAGS="-I$BORINGSSL_INC" -DCMAKE_CXX_FLAGS="-I$BORINGSSL_INC" \
  ..;

# Hack to fix build files, these actions must execute after cmake, otherwise may cause file conflict
# copy sys/user.h for libbase
cp -av "$PORTING_ROOT/adb/include/sys" "$SOURCE_ROOT/android-tools/vendor/libbase/include/";
ln -sfv "$SOURCE_ROOT/android-tools/vendor/core/diagnose_usb/include/diagnose_usb.h" \
  "$SOURCE_ROOT/android-tools/vendor/core/include"

# Hack source codes
cp -av "$PORTING_ROOT/adb/client/"* "$SOURCE_ROOT/android-tools/vendor/adb/client/";

# Build all configured targets; avoid hardcoding target names which may differ across setups
cmake --build . -- -j16

find . -name "*.a" -exec cp -av {} $FULL_OUTPUT \;

# Build tiny wrapper library that exports adb_*_porting symbols
echo "→ Build libadb-porting.a (wrapper symbols)"
SDK_PATH=$(xcrun --sdk $SDK_NAME --show-sdk-path)
OBJ_DIR="$cmake_root/obj"
mkdir -p "$OBJ_DIR"

# Choose correct min version flag per SDK
MIN_VER_FLAG="-miphoneos-version-min=$DEPLOYMENT_TARGET"
if [[ $SDK_NAME == iphonesimulator ]]; then
  MIN_VER_FLAG="-mios-simulator-version-min=$DEPLOYMENT_TARGET"
fi

COMMON_CXXFLAGS=(
  -std=gnu++17 -fno-exceptions -fno-rtti
  -isysroot "$SDK_PATH" -arch $ARCH_NAME
  $MIN_VER_FLAG
  -I"$PORTING_ROOT/adb"
  -I"$PORTING_ROOT/adb/client"
  -I"$SOURCE_ROOT/android-tools/vendor"
  -I"$SOURCE_ROOT/android-tools/vendor/adb"
  -I"$SOURCE_ROOT/android-tools/vendor/adb/client"
  -I"$SOURCE_ROOT/android-tools/vendor/core/include"
  -I"$SOURCE_ROOT/android-tools/vendor/libbase/include"
  -I"$SOURCE_ROOT/external/protobuf/src"
)

# 1) Compile the thin wrapper (no heavy includes)
xcrun --sdk $SDK_NAME clang++ "${COMMON_CXXFLAGS[@]}" \
  -c "$PORTING_ROOT/adb/client/adb_porting.cpp" -o "$OBJ_DIR/adb_porting.o"

# Archive into a static library and place it in the output folder picked up by the top-level libtool step
libtool -static -o "$FULL_OUTPUT/libadb-porting.a" "$OBJ_DIR/adb_porting.o"
