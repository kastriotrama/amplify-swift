// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let platforms: [SupportedPlatform] = [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v9)
]
let dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/aws-amplify/aws-sdk-ios-spm", exact: "2.38.0"),
    .package(url: "https://github.com/stephencelis/SQLite.swift.git", exact: "0.15.3"),
    .package(url: "https://github.com/mattgallagher/CwlPreconditionTesting.git", from: "2.1.0"),
    .package(url: "https://github.com/aws-amplify/amplify-swift-utils-notifications.git", from: "1.1.0")
]

let amplifyTargets: [Target] = [
    .target(
        name: "Amplify",
        path: "Amplify",
        exclude: [
            "Info.plist",
            "Categories/DataStore/Model/Temporal/README.md"
        ],
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy")
        ]
    ),
    .target(
        name: "AWSPluginsCore",
        dependencies: [
            "Amplify"
        ],
        path: "AmplifyPlugins/Core/AWSPluginsCore",
        exclude: [
            "Info.plist"
        ],
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy")
        ]
    ),
    .target(
        name: "InternalAmplifyCredentials",
        dependencies: [
            "Amplify",
            "AWSPluginsCore",
            .product(name: "AWSClientRuntime", package: "aws-sdk-swift")
        ],
        path: "AmplifyPlugins/Core/AmplifyCredentials",
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy")
        ]
    ),
    .target(
        name: "AmplifyTestCommon",
        dependencies: [
            "Amplify",
            "CwlPreconditionTesting",
            "InternalAmplifyCredentials"
        ],
        path: "AmplifyTestCommon",
        exclude: [
            "Info.plist",
            "Models/schema.graphql",
            "Models/Restaurant/schema.graphql",
            "Models/TeamProject/schema.graphql",
            "Models/M2MPostEditorUser/schema.graphql",
            "Models/Collection/connection-schema.graphql",
            "Models/TransformerV2/schema.graphql",
            "Models/CustomPrimaryKey/primarykey_schema.graphql"
        ]
    ),
    .testTarget(
        name: "AmplifyTests",
        dependencies: [
            "Amplify",
            "AmplifyTestCommon",
            "AmplifyAsyncTesting"
        ],
        path: "AmplifyTests",
        exclude: [
            "Info.plist",
            "CoreTests/README.md"
        ]
    ),
    .target(
        name: "AmplifyAsyncTesting",
        dependencies: [],
        path: "AmplifyAsyncTesting/Sources/AsyncTesting",
        linkerSettings: [.linkedFramework("XCTest")]
    ),
    .testTarget(
        name: "AmplifyAsyncTestingTests",
        dependencies: ["AmplifyAsyncTesting"],
        path: "AmplifyAsyncTesting/Tests/AsyncTestingTests"
    ),
    .target(
        name: "AWSPluginsTestCommon",
        dependencies: [
            "Amplify",
            "AWSPluginsCore",
            "InternalAmplifyCredentials",
            .product(name: "AWSClientRuntime", package: "aws-sdk-swift")
        ],
        path: "AmplifyPlugins/Core/AWSPluginsTestCommon",
        exclude: [
            "Info.plist"
        ]
    ),
    .testTarget(
        name: "AWSPluginsCoreTests",
        dependencies: [
            "AWSPluginsCore",
            "AmplifyTestCommon"
        ],
        path: "AmplifyPlugins/Core/AWSPluginsCoreTests",
        exclude: [
            "Info.plist"
        ]
    ),
    .testTarget(
        name: "InternalAmplifyCredentialsTests",
        dependencies: [
            "InternalAmplifyCredentials",
            "AmplifyTestCommon",
            .product(name: "AWSClientRuntime", package: "aws-sdk-swift")
        ],
        path: "AmplifyPlugins/Core/AmplifyCredentialsTests"
    )
]

let apiTargets: [Target] = [
    .target(
        name: "AWSAPIPlugin",
        dependencies: [
            .target(name: "Amplify"),
            .target(name: "InternalAmplifyCredentials")
        ],
        path: "AmplifyPlugins/API/Sources/AWSAPIPlugin",
        exclude: [
            "Info.plist",
            "AWSAPIPlugin.md"
        ],
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy")
        ]
    ),
    .testTarget(
        name: "AWSAPIPluginTests",
        dependencies: [
            "AWSAPIPlugin",
            "AmplifyTestCommon",
            "AWSPluginsTestCommon",
            "AmplifyAsyncTesting"
        ],
        path: "AmplifyPlugins/API/Tests/AWSAPIPluginTests",
        exclude: [
            "Info.plist"
        ]
    )
]

let storageTargets: [Target] = [
    .target(
        name: "AWSS3StoragePlugin",
        dependencies: [
            .target(name: "Amplify"),
            .target(name: "AWSPluginsCore"),
            .target(name: "InternalAmplifyCredentials"),
            .product(name: "AWSS3", package: "aws-sdk-swift")],
        path: "AmplifyPlugins/Storage/Sources/AWSS3StoragePlugin",
        exclude: [
            "Resources/Info.plist"
        ],
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy")
        ]
    ),
    .testTarget(
        name: "AWSS3StoragePluginTests",
        dependencies: [
            "AWSS3StoragePlugin",
            "AmplifyTestCommon",
            "AWSPluginsTestCommon",
            "AmplifyAsyncTesting"
        ],
        path: "AmplifyPlugins/Storage/Tests/AWSS3StoragePluginTests",
        exclude: [
            "Resources/Info.plist"
        ]
    )
]

let targets: [Target] = amplifyTargets
    + apiTargets
    + authTargets
    + storageTargets

let package = Package(
    name: "Amplify",
    platforms: platforms,
    products: [
        .library(
            name: "Amplify",
            targets: ["Amplify"]
        ),
        .library(
            name: "AWSPluginsCore",
            targets: ["AWSPluginsCore"]
        ),
        .library(
            name: "AWSAPIPlugin",
            targets: ["AWSAPIPlugin"]
        ),
        .library(
            name: "AWSS3StoragePlugin",
            targets: ["AWSS3StoragePlugin"]
        ),
    ],
    dependencies: dependencies,
    targets: targets
)
