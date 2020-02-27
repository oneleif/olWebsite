import XCTest
@testable import AppTests

XCTMain([
    testCase(RegisterUserTests.allTests),
    testCase(ValidatorServiceTests.allTests)
])
