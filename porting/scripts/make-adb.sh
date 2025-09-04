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

cmake -DCMAKE_OSX_SYSROOT=$SDK_NAME -DCMAKE_OSX_ARCHITECTURES=$ARCH_NAME  \
	-DCMAKE_OSX_DEPLOYMENT_TARGET=$DEPLOYMENT_TARGET -DCMAKE_BUILD_TYPE=Debug ..;

# Hack to fix build files, these actions must execute after cmake, otherwise may cause file conflict
# copy sys/user.h for libbase
cp -av "$PORTING_ROOT/adb/include/sys" "$SOURCE_ROOT/android-tools/vendor/libbase/include/";
ln -sfv "$SOURCE_ROOT/android-tools/vendor/core/diagnose_usb/include/diagnose_usb.h" \
  "$SOURCE_ROOT/android-tools/vendor/core/include"

# Hack source codes
cp -av "$PORTING_ROOT/adb/client/"* "$SOURCE_ROOT/android-tools/vendor/adb/client/";

make -j16 libadb crypto decrepit libcutils libzip libdiagnoseusb libbase \
	libadb_crypto_defaults libcrypto libadb_tls_connection_defaults;

find . -name "*.a" -exec cp -av {} $FULL_OUTPUT \;

# Build tiny wrapper library that exports adb_*_porting symbols
echo "→ Build libadb-porting.a (wrapper symbols)"
SDK_PATH=$(xcrun --sdk $SDK_NAME --show-sdk-path)
OBJ_DIR="$cmake_root/obj"
mkdir -p "$OBJ_DIR"

# Compile the wrapper as a standalone object (no linking needed)
xcrun --sdk $SDK_NAME clang++ -std=c++17 -fobjc-arc -fno-exceptions -fno-rtti \
  -isysroot "$SDK_PATH" -arch $ARCH_NAME \
  -I"$SOURCE_ROOT/android-tools/vendor" \
  -I"$SOURCE_ROOT/android-tools/vendor/adb" \
  -I"$SOURCE_ROOT/android-tools/vendor/adb/client" \
  -I"$SOURCE_ROOT/android-tools/vendor/core/include" \
  -I"$SOURCE_ROOT/android-tools/vendor/libbase/include" \
  -c "$PORTING_ROOT/adb/client/adb_porting.cpp" -o "$OBJ_DIR/adb_porting.o"

# Archive into a static library and place it in the output folder picked up by the top-level libtool step
libtool -static -o "$FULL_OUTPUT/libadb-porting.a" "$OBJ_DIR/adb_porting.o"
