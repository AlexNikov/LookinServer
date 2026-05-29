// swift-tools-version:5.3

import PackageDescription

/// Debug-only flags for LookinServer SPM layout.
private let debugLookinCXXSettings: [CXXSetting] = [
    .define("SHOULD_COMPILE_LOOKIN_SERVER", to: "1", .when(platforms: [.iOS, .tvOS], configuration: .debug)),
    .define("SPM_LOOKIN_SERVER_ENABLED", to: "1", .when(platforms: [.iOS, .tvOS], configuration: .debug)),
]

private let debugLookinSwiftSettings: [SwiftSetting] = [
    .define("SHOULD_COMPILE_LOOKIN_SERVER", .when(platforms: [.iOS, .tvOS], configuration: .debug)),
    .define("SPM_LOOKIN_SERVER_ENABLED", .when(platforms: [.iOS, .tvOS], configuration: .debug)),
]

private let debugLookinServerCSettings: [CSetting] = [
    .define("SHOULD_COMPILE_LOOKIN_SERVER", to: "1", .when(platforms: [.iOS, .tvOS], configuration: .debug)),
]

/// `LookinDefines.swift` duplicates `LookinVersion.swift` + `LookinRequestTypeCConstants.swift`.
/// `LookinAttrIdentifiers.swift` lives in Shared; CoreSwift excludes the duplicate copy.
private let lookinSharedHeaderDuplicateExcludes: [String] = [
    "LookinDefines.swift",
]

private let lookinCoreSwiftDuplicateExcludes: [String] = [
    "README.md",
    "LookinAttrIdentifiers.swift",
]

private let lookinOthersExcludes: [String] = [
    "README.md",
    "LookinObjCExceptionCatch.m",
]

let package = Package(
    name: "LookinServer",
    platforms: [
        .iOS(.v14),
        .tvOS(.v14),
    ],
    products: [
        .library(
            name: "LookinServer",
            targets: ["LookinServer"]
        ),
    ],
    targets: [
        // MARK: - Foundation (Sources/LookinServerBase)
        .target(
            name: "LookinServerBase",
            dependencies: [],
            path: "Sources/LookinServerBase",
            exclude: [],
            publicHeadersPath: "",
            cSettings: debugLookinServerCSettings,
            swiftSettings: debugLookinSwiftSettings
        ),

        // MARK: - Shared Swift models (Sources/LookinServerShared)
        .target(
            name: "LookinServerShared",
            dependencies: ["LookinServerBase"],
            path: "Sources/LookinServerShared",
            exclude: lookinSharedHeaderDuplicateExcludes,
            swiftSettings: debugLookinSwiftSettings
        ),

        // MARK: - ObjC NSException catch (single .m; linked by downstream targets)
        .target(
            name: "LookinServerCore",
            dependencies: [
                "LookinServerBase",
                "LookinServerShared",
            ],
            path: "Sources/LookinServerOthers",
            sources: ["LookinObjCExceptionCatch.m"],
            publicHeadersPath: "",
            cSettings: debugLookinServerCSettings,
            cxxSettings: debugLookinCXXSettings
        ),

        // MARK: - Peertalk (Sources/LookinServerPeertalk)
        .target(
            name: "LookinServerPeertalk",
            dependencies: [
                "LookinServerBase",
                "LookinServerCore",
            ],
            path: "Sources/LookinServerPeertalk",
            exclude: ["README.md"],
            swiftSettings: debugLookinSwiftSettings
        ),

        // MARK: - MCP (Sources/LookinServerMCP)
        .target(
            name: "LookinServerMCP",
            dependencies: [
                "LookinServerBase",
                "LookinServerCore",
                "LookinServerCoreSwift",
                "LookinServerConnection",
                "LookinServerCategories",
                "LookinServerOthers",
            ],
            path: "Sources/LookinServerMCP",
            exclude: ["README.md"],
            cSettings: debugLookinServerCSettings,
            cxxSettings: debugLookinCXXSettings,
            swiftSettings: debugLookinSwiftSettings
        ),

        // MARK: - Utilities (Sources/LookinServerOthers)
        .target(
            name: "LookinServerOthers",
            dependencies: [
                "LookinServerBase",
                "LookinServerShared",
                "LookinServerCore",
                "LookinServerCategories",
            ],
            path: "Sources/LookinServerOthers",
            exclude: lookinOthersExcludes,
            swiftSettings: debugLookinSwiftSettings
        ),

        // MARK: - Swift inspect makers (Sources/LookinServerCore)
        .target(
            name: "LookinServerCoreSwift",
            dependencies: [
                "LookinServerBase",
                "LookinServerShared",
                "LookinServerCore",
                "LookinServerCategories",
                "LookinServerOthers",
            ],
            path: "Sources/LookinServerCore",
            exclude: lookinCoreSwiftDuplicateExcludes,
            cxxSettings: debugLookinCXXSettings,
            swiftSettings: debugLookinSwiftSettings
        ),

        // MARK: - Swift connection layer (Sources/LookinServerConnection)
        .target(
            name: "LookinServerConnection",
            dependencies: [
                "LookinServerBase",
                "LookinServerShared",
                "LookinServerCore",
                "LookinServerCoreSwift",
                "LookinServerPeertalk",
                "LookinServerCategories",
                "LookinServerOthers",
            ],
            path: "Sources/LookinServerConnection",
            cxxSettings: debugLookinCXXSettings,
            swiftSettings: debugLookinSwiftSettings
        ),

        // MARK: - ObjC +load bootstrap
        .target(
            name: "LookinServerConnectionBootstrap",
            dependencies: ["LookinServerConnection"],
            path: "Sources/LookinServerConnectionBootstrap",
            cSettings: debugLookinServerCSettings
        ),

        // MARK: - Swift UI categories (Sources/LookinServerCategories)
        .target(
            name: "LookinServerCategories",
            dependencies: [
                "LookinServerBase",
                "LookinServerShared",
                "LookinServerCore",
            ],
            path: "Sources/LookinServerCategories",
            exclude: ["README.md"],
            cxxSettings: debugLookinCXXSettings,
            swiftSettings: debugLookinSwiftSettings
        ),

        // MARK: - Public product entry (Sources/LookinServer)
        .target(
            name: "LookinServer",
            dependencies: [
                "LookinServerCore",
                "LookinServerCoreSwift",
                "LookinServerConnection",
                "LookinServerConnectionBootstrap",
                "LookinServerPeertalk",
                "LookinServerCategories",
                "LookinServerOthers",
                "LookinServerMCP",
                "LookinServerShared",
            ],
            path: "Sources/LookinServer",
            swiftSettings: debugLookinSwiftSettings
        ),

        .testTarget(
            name: "LookinServerSharedTests",
            dependencies: ["LookinServerShared", "LookinServerBase", "LookinServerCore"],
            path: "Tests/LookinServerSharedTests",
        ),
    ]
)
