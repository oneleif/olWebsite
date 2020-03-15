import XCTest
@testable import AppTests

XCTMain([
    testCase(RegisterUserTests.allTests),
    testCase(ValidatorServiceTests.allTests),
    testCase(LoginTests.allTests),
    testCase(LogoutTests.allTests),
    testCase(RefreshTokenTests.allTests)
])
