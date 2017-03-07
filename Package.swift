import PackageDescription

let package = Package(
  name: "ExExpress",

  .Package(url: "git@github.com:AlwaysRightInstitute/cows.git",
	         majorVersion: 1, minor: 0),
  .Package(url: "git@github.com:AlwaysRightInstitute/mustache.git", 
	         majorVersion: 0),
  .Package(url: "https://github.com/bignerdranch/Freddy.git",
					 majorVersion: 3, minor: 0),
	
	exclude: [
		"ExExpress.xcodeproj",
		"GNUmakefile",
		"LICENSE",
		"README.md",
		"xcconfig"
	]
)
