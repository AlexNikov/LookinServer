// swift-tools-version:5.3

import PackageDescription

/// Debug-only flags for LookinServer (iOS/tvOS simulator/device).
private let debugLookinCXXSettings: [CXXSetting] = [
    .define("SHOULD_COMPILE_LOOKIN_SERVER", to: "1", .when(platforms: [.iOS, .tvOS], configuration: .debug)),
    .define("SPM_LOOKIN_SERVER_ENABLED", to: "1", .when(platforms: [.iOS, .tvOS], configuration: .debug)),
]

private let debugLookinSwiftSettings: [SwiftSetting] = [
    .define("SHOULD_COMPILE_LOOKIN_SERVER", .when(platforms: [.iOS, .tvOS], configuration: .debug)),
    .define("SPM_LOOKIN_SERVER_ENABLED", .when(platforms: [.iOS, .tvOS], configuration: .debug)),
    .define("LOOKIN_SERVER_MCP", .when(platforms: [.iOS, .tvOS], configuration: .debug)),
]

private let debugLookinServerCSettings: [CSetting] = [
    .define("SHOULD_COMPILE_LOOKIN_SERVER", to: "1", .when(platforms: [.iOS, .tvOS], configuration: .debug)),
]

/// LookinShared pod parity: server/shared compile flags on all platforms.
private let lookinSharedSwiftSettings: [SwiftSetting] = [
    .define("SHOULD_COMPILE_LOOKIN_SERVER"),
]

private let lookinSharedCSettings: [CSetting] = [
    .define("SHOULD_COMPILE_LOOKIN_SERVER", to: "1"),
]

/// Files compiled into LookinShared (also excluded from LookinServer — SPM allows one target per source file).
private let lookinSharedOnlyExcludesFromServer: [String] = [
    "LookinServerCore/LookinDashboardBlueprint.swift",
    "LookinServerCore/LookinAttributeGetter.swift",
    "LookinServerCategories/CALayer+Lookin.swift",
    "LookinServerCategories/NSSet+Lookin.swift",
    "LookinServerCategories/LookinAutoLayoutConstraint.swift",
]

/// LookinServer-only sources (server runtime; shared wire/models live in LookinShared).
private let lookinServerExclusiveSources: [String] = [
    "LookinServerShared/LKS_ObjectRegistry.swift",
    "LookinServerCategories",
    "LookinServerCore",
    "LookinServerConnection",
    "LookinServerConnectionBootstrap",
    "LookinServerMCP",
    "LookinServerOthers",
    "LookinServer",
]

private let lookinServerExcludes: [String] = [
    "LookinServerShared/LookinDefines.swift",
    "LookinServerCore/LookinAttrIdentifiers.swift",
    "LookinServerOthers/LookinObjCExceptionCatch.m",
    "LookinServerCategories/README.md",
    "LookinServerCore/README.md",
    "LookinServerPeertalk/README.md",
    "LookinServerMCP/README.md",
    "LookinServerOthers/README.md",
] + lookinSharedOnlyExcludesFromServer

/// Unified LookinShared target — mirrors LookinShared.podspec.
private let lookinSharedSources: [String] = [
    "LookinServerBase/LookinIvarTrace.swift",
    "LookinServerShared",
    "LookinServerCore/LookinDashboardBlueprint.swift",
    "LookinServerCore/LookinAttributeGetter.swift",
    "LookinServerPeertalk",
    "LookinServerCategories/CALayer+Lookin.swift",
    "LookinServerCategories/NSSet+Lookin.swift",
    "LookinServerCategories/LookinAutoLayoutConstraint.swift",
]

private let lookinSharedExcludes: [String] = [
    "LookinServerShared/LookinDefines.swift",
    "LookinServerShared/LKS_ObjectRegistry.swift",
    "LookinServerShared/MacLookinClientCompatibility.md",
    "LookinServerPeertalk/README.md",
]

let package = Package(
    name: "LookinServer",
    platforms: [
        .iOS(.v14),
        .tvOS(.v14),
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "LookinServer",
            targets: ["LookinServer"]
        ),
        .library(
            name: "LookinShared",
            targets: ["LookinShared"]
        ),
    ],
    targets: [
        /// Single ObjC translation unit — SPM 5.3 cannot mix .m + Swift in one target.
        .target(
            name: "LookinServerObjCBridge",
            dependencies: [],
            path: "Sources/LookinServerOthers",
            sources: ["LookinObjCExceptionCatch.m"],
            publicHeadersPath: ".",
            cSettings: debugLookinServerCSettings
        ),

        .target(
            name: "LookinShared",
            dependencies: ["LookinServerObjCBridge"],
            path: "Sources",
            exclude: lookinSharedExcludes,
            sources: lookinSharedSources,
            publicHeadersPath: "LookinServerBase",
            cSettings: lookinSharedCSettings,
            swiftSettings: lookinSharedSwiftSettings
        ),

        .target(
            name: "LookinServer",
            dependencies: ["LookinServerObjCBridge", "LookinShared"],
            path: "Sources",
            exclude: lookinServerExcludes,
            sources: lookinServerExclusiveSources,
            cSettings: debugLookinServerCSettings,
            cxxSettings: debugLookinCXXSettings,
            swiftSettings: debugLookinSwiftSettings
        ),

        .testTarget(
            name: "LookinServerSharedTests",
            dependencies: ["LookinServer"],
            path: "Tests/LookinServerSharedTests"
        ),

        .testTarget(
            name: "LookinServerConnectionTests",
            dependencies: ["LookinServer"],
            path: "Tests/LookinServerConnectionTests",
            swiftSettings: debugLookinSwiftSettings
        ),
    ]
)
