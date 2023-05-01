#!/bin/bash

set -e

pwd

if [[ "$1" == "clean" ]]; then
	echo "Clean build ..."
rm -rf ./out/ios_debug_sim_unopt
rm -rf ./out/ios_debug_unopt
rm -rf ./out/ios_release
rm -rf ./out/host_debug_unopt
rm -rf ./out/host_release
fi

if [[ "$1" == "clean" ]] || [[ ! -d ./out/ios_debug_sim_unopt ]]; then
./flutter/tools/gn --ios --simulator --unoptimized
fi

ninja -C out/ios_debug_sim_unopt

if [[ "$1" == "clean" ]] || [[ ! -d ./out/ios_debug_unopt ]]; then
./flutter/tools/gn --ios --unoptimized --no-goma --bitcode
fi

ninja -C out/ios_debug_unopt

if [[ "$1" == "clean" ]] || [[ ! -d ./out/ios_release ]]; then
./flutter/tools/gn --ios --runtime-mode=release --no-goma --bitcode
fi

ninja -C out/ios_release

if [[ "$1" == "clean" ]] || [[ ! -d ./out/host_debug_unopt ]]; then
./flutter/tools/gn --unoptimized --no-prebuilt-dart-sdk
fi
ninja -C out/host_debug_unopt

if [[ "$1" == "clean" ]] || [[ ! -d ./out/host_release ]]; then
./flutter/tools/gn --no-lto --runtime-mode=release --no-prebuilt-dart-sdk
fi
ninja -C out/host_release