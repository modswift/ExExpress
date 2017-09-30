import PackageDescription

let package = Package(
  name: "ExExpress",

  dependencies: [
    .Package(url: "https://github.com/AlwaysRightInstitute/mustache.git",
             majorVersion: 0, minor: 5),
    
    .Package(url: "https://github.com/modswift/Freddy.git",
             majorVersion: 3, minor: 0)
    /* 3.0.2 fails on Linux
	  .Package(url: "https://github.com/bignerdranch/Freddy.git",
						 majorVersion: 3, minor: 0),
     */
  ],
	
  exclude: [
    "ExExpress.xcodeproj",
    "GNUmakefile",
    "LICENSE",
    "README.md",
    "xcconfig"
  ]
)

#if swift(>=3.1)
  package.swiftLanguageVersions = [ 3, 4 ]
#endif

