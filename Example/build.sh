### Device

set -eux

export TOOLCHAINS=org.swift.59202403011a

swift-build --product Example --experimental-swift-sdk playdate -c release

cp .build/armv7em-none-none-eabi/release/Example Source/pdex.elf

### Simulator

swift-build --product Example_Simulator -c release
cp .build/arm64-apple-macosx/release/libExample_Simulator.dylib Source/pdex.dylib

pdc Source Example.pdx
