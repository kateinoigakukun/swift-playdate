# Swift on Playdate Demonstration

https://github.com/kateinoigakukun/swift-playdate/assets/11702759/78dc07b4-168b-4d53-a779-0e45492b857f

## Want to build by yourself?

1. Install `swift-DEVELOPMENT-SNAPSHOT-2024-03-01-a` toolchain from [Swift.org](https://swift.org/download/)
2. Build SwiftPM with [a patch](https://github.com/apple/swift-package-manager/pull/7417), and include it in `PATH`.

```console
$ swift experimental-sdk install ./SwiftSDKs/Playdate.artifactbundle
$ cd Example
$ ./build.sh
$ open Example.pdx
```
