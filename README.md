# DialectalCSV (`csv-dialect-swift`)
[![TravisCI Build Status](https://travis-ci.org/chrispomeroyhale/csv-dialect-swift.svg?branch=main)](https://travis-ci.org/chrispomeroyhale/csv-dialect-swift)
[![Coverage Status](https://coveralls.io/repos/github/chrispomeroyhale/csv-dialect-swift/badge.svg?branch=main)](https://coveralls.io/github/chrispomeroyhale/csv-dialect-swift?branch=main)

A multi-dialect CSV parser written in Swift for importing and exporting the delectable flavors of comma separated values documents. This library implements [Frictionless Data's CSV Dialect](https://frictionlessdata.io/specs/csv-dialect/) spec which acknowledges that the CSV RFC 4180 is retroactive and that in practice numerous flavors of documents and exporters exist. The library also supports streaming of data incrementally for a low peak memory footprint.

DialectalCSV provides a tiered interface for working with CSV. At its lowest level is a pair of parsers capable of streaming partial data. A higher level interface is available for working with file URLs using `FileHandle` for data streaming. And a convenience class `Document` enables working with in-memory representations.

The library is backed by a small set of unit tests which provides a basis for regression testing.

## Requirements
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fchrispomeroyhale%2Fcsv-dialect-swift%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/chrispomeroyhale/csv-dialect-swift)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fchrispomeroyhale%2Fcsv-dialect-swift%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/chrispomeroyhale/csv-dialect-swift)

 * Source compatible with Swift 4.2 and up
 * Targets Apple platforms, namely macOS and iOS
 * Relies upon `Foundation` and Swift standard library APIs only
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

## Usage
For additional examples take a look at the test cases and consult the interface documentation including the possible error cases that can be thrown.

### Opening a CSV Document in Memory
Open a tab separated value (TSV) file from in-memory data:

    import DialectalCSV

    var dialect = Dialect()
    dialect.delimiter = "\t"
    dialect.header = false
    let document = try Document(data: data, dialect: dialect)

### Creating a CSV Document
Create a CSV document from Foundation objects and set a custom null sequence pattern for nil values.

    import DialectalCSV

    let headerAndRows = [ ["name", "nickname"], ["Nelson Mandela", "Madiba"] ]
    let document = Document(allRows: headerAndRows)
    document.records.append(["Mahatma Gandhi", nil])

    let outputFileHandle = try FileHandle(forWritingTo: outputURL)
    var dialect = Dialect()
    dialect.nullSequence = "n/a"
    try document.export(fileHandle: outputFileHandle, dialect: dialect)

### Converting a CSV Document via Data Streaming
Convert a CSV document to a tab separated value (TSV). Stream it into a buffer of the default byte length instead of loading it all into memory at once.

    import DialectalCSV

    FileManager.default.createFile(atPath: outputURL.path, contents: nil)
    let outputFileHandle = try FileHandle(forWritingTo: outputURL)
    var outputDialect = Dialect()
    outputDialect.delimiter = "\t"
    let outputHandler = OutputHandler(fileHandle: outputFileHandle, dialect: outputDialect)

    let inputFileHandle = try FileHandle(forReadingFrom: inputURL)
    let inputHandler = InputHandler(fileHandle: inputFileHandle, dialect: inputDialect)
    inputHandler.delegate = outputHandler

    try inputHandler.readToEndOfFile()

## Integrating into Your Project
This project is intended to be distributed via Swift Package Manager. Alternative methods are possible if SPM is not an option.

### Xcode via Swift Package Manager (Recommended)
In Xcode 11 Swift Package Manager is now integrated into Xcode. Add this package as you would any other Swift package.

This method was not reliable until about Xcode 11.2. There is no xcodeproj for older versions of Xcode although one can be generated. See the Xcode Subproject option.

### Manual Swift Package Manager (Recommended)
Add the following dependency to your `Package.swift`'s `dependencies` and use `DialectalCSV` as the name of the dependency. You may wish to change the branch or use a particular revision.

	.package(url: "git@github.com:chrispomeroyhale/csv-dialect-swift.git", .branch("main"))

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
