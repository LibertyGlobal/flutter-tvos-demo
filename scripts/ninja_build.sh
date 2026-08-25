#!/bin/bash
set -e
set +x
set +v

RED='\033[0;31m'
NOCOLOR='\033[0m'

if [[ $(uname -m) == "arm64" ]]; then
    echo "Host: Mac - Apple Silicon (arm64)"
    HOST_CPU="arm64"
    SIM_CPU="arm64"
    OUTPUT_POSTFIX="_arm64"
else
    echo "Host: Mac - Intel (x64)"
    HOST_CPU="x64"
    SIM_CPU="x64"
    OUTPUT_POSTFIX=""
fi

if [[ "$1" == "clean" ]]; then
    echo "Clean build ..."
    rm -irf ./out/ios_debug_sim_unopt$OUTPUT_POSTFIX
    rm -rf ./out/ios_debug_unopt$OUTPUT_POSTFIX
    rm -rf ./out/ios_release$OUTPUT_POSTFIX
    rm -rf ./out/host_debug_unopt$OUTPUT_POSTFIX
    rm -rf ./out/host_release$OUTPUT_POSTFIX
fi
if [[ "$1" == "clean" ]] || [[ ! -d ./out/host_release$OUTPUT_POSTFIX ]]; then
   ./flutter/tools/gn --no-goma --no-lto --runtime-mode=release --no-enable-unittests --mac-cpu=$HOST_CPU --no-prebuilt-dart-sdk
fi
ninja -C out/host_release$OUTPUT_POSTFIX -j 4
if [[ "$1" == "clean" ]] || [[ ! -d ./out/host_debug_unopt$OUTPUT_POSTFIX ]]; then
   ./flutter/tools/gn --no-goma --unoptimized --no-enable-unittests --mac-cpu=$HOST_CPU --no-prebuilt-dart-sdk
fi
ninja -C out/host_debug_unopt$OUTPUT_POSTFIX -j 4
if [[ "$1" == "clean" ]] || [[ ! -d ./out/ios_debug_sim_unopt$OUTPUT_POSTFIX ]]; then
    ./flutter/tools/gn --ios --no-goma --simulator --unoptimized --simulator-cpu=$SIM_CPU --no-prebuilt-dart-sdk
fi
ninja -C out/ios_debug_sim_unopt$OUTPUT_POSTFIX
if [[ "$1" == "clean" ]] || [[ ! -d ./out/ios_debug_unopt$OUTPUT_POSTFIX ]]; then
    ./flutter/tools/gn --ios --no-goma --unoptimized --mac-cpu=$HOST_CPU --no-prebuilt-dart-sdk
fi
ninja -C out/ios_debug_unopt$OUTPUT_POSTFIX
if [[ "$1" == "clean" ]] || [[ ! -d ./out/ios_release$OUTPUT_POSTFIX ]]; then
   ./flutter/tools/gn --ios --no-goma --runtime-mode=release --mac-cpu=$HOST_CPU --no-prebuilt-dart-sdk
fi
ninja -C out/ios_release$OUTPUT_POSTFIX