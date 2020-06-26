# DialectalCSV (`csv-dialect-swift`)
[![TravisCI Build Status](https://travis-ci.org/chrispomeroyhale/csv-dialect-swift.svg?branch=master)](https://travis-ci.org/chrispomeroyhale/csv-dialect-swift)
[![Coverage Status](https://coveralls.io/repos/github/chrispomeroyhale/csv-dialect-swift/badge.svg?branch=master)](https://coveralls.io/github/chrispomeroyhale/csv-dialect-swift?branch=master)

A multi-[dialect](https://frictionlessdata.io/specs/csv-dialect/) CSV parser written in Swift for importing and exporting the delectable flavors of comma separated values documents.

This library provides a tiered interface for working with CSV. At its core is a pair of parsers capable of handling partial data. A higher level interface is available for working with file URLs using `FileHandle` for data streaming. And a convenience class `Document` enables working with in-memory representations.

The library is backed by a small set of unit tests which provides a basis for regression testing.

## Requirements
 * Source compatibility with Swift 4.2
 * Targets Apple platforms, namely macOS and iOS
    * Linux support unavailable due to an incomplete `Scanner` implementation in `swift-corelibs-foundation`

## Feature Status
| CSV Dialect Property  | Status      |
|:----------------------|:------------|
| Delimiter             | Available   |
| Line Terminator       | Available   |
| Quote Character       | Available   |
| Double Quote          | Available   |
| Escape Character      | Available   |
| Null Sequence         | Available   |
| Skip Initial Space    | Available   |
| Header                | Available   |
| Comment Character     | Unavailable |
| Case Sensitive Header | *N/A*       |

This implementation is compatible with `csvddfVersion` 1.2.

## Integrating into Your Project
This project is set up using Swift Package Manager. Alternative methods are possible if SPM is not an option.

### Manual Swift Package Manager
Add the following dependency to your `Package.swift`'s `dependencies` and use `DialectalCSV` as the name of the dependency. You may wish to change the branch or use a particular revision.

	.package(url: "git@github.com:slythfox/csv-dialect-swift.git", .branch("master"))

### Xcode Swift Package Manager
Instead of providing an Xcode project this project uses Swift Package Manager (SPM) which relies on dependents to generate their own Xcode project to build the library. Presently Xcode has no knowledge of Swift Package Manager and requires manual configuration using SPM tool for generating Xcode projects.

### Carthage (Not Recommended)
While Carthage does not officially support Swift Package Manager it is possible to integrate it manually. Create a "Run Script" phase and position it to appear before the "Compile Sources" phase to automate updating, generating the Xcode project, and building of dependencies. After running the script follow Carthage's documentation for integrating the dependency into your project.

	carthage update --no-build

	pushd "Carthage/Checkouts/csv-dialect-swift"
	swift package generate-xcodeproj --xcconfig-overrides ./Configuration.xcconfig
	popd

	carthage build --cache-builds

### Xcode Subproject (Not Recommended)
With this option, first either set up this library with an external tool for managing dependencies (such as git submodules) or commit the library's source directly. Then generate an Xcode project using:

	swift package generate-xcodeproj --xcconfig-overrides ./Configuration.xcconfig

Add the generated Xcode project as a subproject and configure your project to use the `DialectalCSV` target dependency along with all the traditional steps for manually integrating a library.

You may choose to add a "Run Script" phase that generates the Xcode project for you, such as:

	pushd "Vendors/DialectalCSV"
	if [ ! -f ./csv-dialect-swift.xcodeproj/project.pbxproj ]; then
		swift package generate-xcodeproj --xcconfig-overrides ./Configuration.xcconfig
	else
		echo "Skipping Xcode project generation for 'DialectalCSV'."
	fi
	popd

Note that the caveat with this solution is you will still need to remove the generated Xcode project between upgrades which is a potential source of human error such as when switching branches that use different versions of the library.

## License
Licensed under a 3-clause BSD license. See `License.txt`.
