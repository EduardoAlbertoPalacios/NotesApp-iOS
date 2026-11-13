// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "NotesKit",
    defaultLocalization: "es",
    platforms: [.iOS("27.0")],
    products: [
        .library(name: "Common", targets: ["Common"]),
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Data", targets: ["Data"]),
        .library(name: "Presentation", targets: ["Presentation"]),
    ],
    targets: [
        .target(name: "Common"),
        .target(name: "Domain", dependencies: ["Common"]),
        .target(name: "Data", dependencies: ["Domain", "Common"]),
        .target(
            name: "Presentation",
            dependencies: ["Domain", "Common"],
            resources: [.process("Resources")]
        ),
        .testTarget(name: "DomainTests", dependencies: ["Domain", "Common"]),
        .testTarget(name: "DataTests", dependencies: ["Data", "Domain", "Common"]),
        .testTarget(name: "PresentationTests", dependencies: ["Presentation", "Domain", "Common"]),
    ]
)
