import XCTest

#if !os(macOS) && !os(iOS) && !os(tvOS) 
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ExportTests.allTests),
        testCase(ImportTests.allTests),
        testCase(IntegrationTests.allTests),
    ]
}
#endif
