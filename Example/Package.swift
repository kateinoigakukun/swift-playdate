// swift-tools-version: 5.10

import PackageDescription
import Foundation

func defaultSDKPath() -> String {
    var config = try! String(contentsOfFile: "\(Context.environment["HOME"]!)/.Playdate/config")
        .split(separator: "\n").first!
    config.removeFirst("SDKRoot ".count)
    return String(config)
}

let PLAYDATE_SDK_PATH = Context.environment["PLAYDATE_SDK_PATH"] ?? defaultSDKPath()

let package = Package(
    name: "Example",
    products: [
        .executable(name: "Example", targets: ["Example"]),
        .library(name: "Example_Simulator", type: .dynamic, targets: ["Example_Simulator"]),
    ],
    dependencies: [
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "Example",
            swiftSettings: [
                .enableExperimentalFeature("Embedded"),
                .unsafeFlags(["-I", "../Sources/_CPlaydate"]),
                .unsafeFlags([
                    "-Xfrontend", "-disable-stack-protector",
                    "-Xfrontend", "-experimental-platform-c-calling-convention=arm_aapcs_vfp",
                    "-Xcc", "-DTARGET_EXTENSION=1",
                    "-Xcc", "-DTARGET_PLAYDATE=1",
                    "-Xcc", "-D__FPU_USED=1",
                    "-Xcc", "-I\(PLAYDATE_SDK_PATH)/C_API",
                    "-Xcc", "-I/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/arm-none-eabi/include",
                    "-Xcc", "-falign-functions=16",
                    "-Xcc", "-fshort-enums",
                    "-Xcc", "-mcpu=cortex-m7",
                    "-Xcc", "-mfloat-abi=hard",
                    "-Xcc", "-mfpu=fpv5-sp-d16",
                    "-Xcc", "-mthumb",
                ]),
            ]),
        .target(
            name: "Example_Simulator",
            swiftSettings: [
                .enableExperimentalFeature("Embedded", .when(platforms: [.custom("none")])),
                .unsafeFlags(["-I", "../Sources/_CPlaydate"]),
                .unsafeFlags([
                    "-Xcc", "-I\(PLAYDATE_SDK_PATH)/C_API",
                    "-Xcc", "-DTARGET_EXTENSION=1",
                    "-Xcc", "-DTARGET_SIMULATOR=1",
                ]),
            ]),
    ]
)
