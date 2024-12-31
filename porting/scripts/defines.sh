# Common Supports:
# - TARGET=lz4/iphoneos/arm64
# - OUTPUT=...

[[ -z "$TARGET" ]] && echo "** ERROR: TARGET is REQUIRED." && exit 1;
[[ -z "$OUTPUT" ]] && echo "** ERROR: OUTPUT is REQUIRED." && exit 1;

LIB_NAME=$(echo "$TARGET" | cut -d/ -f1);
SDK_NAME=$(echo "$TARGET" | cut -d/ -f2);
ARCH_NAME=$(echo "$TARGET" | cut -d/ -f3);

# Src root
SOURCE_ROOT=$(cd "$(dirname $0)/../.." && pwd);

# Porting root
PORTING_ROOT=$SOURCE_ROOT/porting;

# Prepare output path
FULL_OUTPUT=$(cd $OUTPUT && pwd)/$SDK_NAME/$ARCH_NAME;
[[ ! -d $FULL_OUTPUT ]] && mkdir -p $FULL_OUTPUT;

# platform
if [[ $SDK_NAME == "iphoneos" ]]; then
    PLATFORM="OS64"
fi
if [[ $SDK_NAME == "iphonesimulator" ]]; then
    if [[ $ARCH_NAME == "arm64" ]]; then
        PLATFORM="SIMULATORARM64"
    else
        PLATFORM="SIMULATOR64"
    fi
fi
if [[ $SDK_NAME == "appletvos" ]]; then
    PLATFORM="TVOS"
fi
if [[ $SDK_NAME == "appletvsimulator" ]]; then
    if [[ $ARCH_NAME == "arm64" ]]; then
        PLATFORM="SIMULATORARM64_TVOS"
    else
        PLATFORM="SIMULATOR_TVOS"
    fi
fi

# Setup iphone deploy target
DEPLOYMENT_TARGET=12.0;

# Setup toolchains
if [[ $SDK_NAME == *iphone* ]]; then
	CMAKE_TOOLCHAIN_FILE=$SOURCE_ROOT/ios-cmake/ios.toolchain.cmake;
fi
if [[ $SDK_NAME == *appletv* ]]; then
	CMAKE_TOOLCHAIN_FILE=$SOURCE_ROOT/ios-cmake/ios.toolchain.cmake;
fi

# Print summary
echo " - Lib Name: $LIB_NAME";
echo " - SDK Name: $SDK_NAME";
echo " - Arch Name: $ARCH_NAME";
echo " - CMake Toolchain: $CMAKE_TOOLCHAIN_FILE";
echo " - CMake PLATFORM: $PLATFORM";
