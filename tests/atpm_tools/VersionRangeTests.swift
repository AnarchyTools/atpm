// Copyright (c) 2016 Anarchy Tools Contributors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
@testable import atpm_tools

import XCTest
class VersionRangeTests: XCTestCase {
    
    // MARK: - Initialization tests
    func testInitSimple() throws {
    	let v = VersionRange(versionString: "1.2.3")
        XCTAssert(v.min == Version(string: "1.2.3"))
        XCTAssert(v.max == Version(string: "1.2.3"))
        XCTAssert(v.minInclusive == true)
        XCTAssert(v.maxInclusive == true)
        XCTAssert(v.description == "==1.2.3")
    }

    func testInitSmaller() throws {
        let v = VersionRange(versionString: "<1.2.3")
        XCTAssert(v.min == nil)
        XCTAssert(v.max == Version(string: "1.2.3"))
        XCTAssert(v.minInclusive == nil)
        XCTAssert(v.maxInclusive == false)
        XCTAssert(v.description == "<1.2.3")
    }

    func testInitBigger() throws {
        let v = VersionRange(versionString: ">1.2.3")
        XCTAssert(v.min == Version(string: "1.2.3"))
        XCTAssert(v.max == nil)
        XCTAssert(v.minInclusive == false)
        XCTAssert(v.maxInclusive == nil)
        XCTAssert(v.description == ">1.2.3")
    }

    func testInitSmallerEqual() throws {
        let v = VersionRange(versionString: "<=1.2.3")
        XCTAssert(v.min == nil)
        XCTAssert(v.max == Version(string: "1.2.3"))
        XCTAssert(v.minInclusive == nil)
        XCTAssert(v.maxInclusive == true)
        XCTAssert(v.description == "<=1.2.3")
    }

    func testInitBiggerEqual() throws {
        let v = VersionRange(versionString: ">=1.2.3")
        XCTAssert(v.min == Version(string: "1.2.3"))
        XCTAssert(v.max == nil)
        XCTAssert(v.minInclusive == true)
        XCTAssert(v.maxInclusive == nil)
        XCTAssert(v.description == ">=1.2.3")
    }

    func testInitEqual() throws {
        let v = VersionRange(versionString: "==1.2.3")
        XCTAssert(v.min == Version(string: "1.2.3"))
        XCTAssert(v.max == Version(string: "1.2.3"))
        XCTAssert(v.minInclusive == true)
        XCTAssert(v.maxInclusive == true)
        XCTAssert(v.description == "==1.2.3")
    }

    // MARK: - Valid combination tests
    func testCombineWithLowerBound() throws {
        let v = VersionRange(versionString: "<2.0.0")
        try v.combine(">1.0.1")
        XCTAssert(v.min == Version(string: "1.0.1"))
        XCTAssert(v.max == Version(string: "2.0.0"))
        XCTAssert(v.minInclusive == false)
        XCTAssert(v.maxInclusive == false)
        XCTAssert(v.description == ">1.0.1, <2.0.0")
    }

    func testCombineWithUpperBound() throws {
        let v = VersionRange(versionString: ">1.0.1")
        try v.combine("<2.0.0")
        XCTAssert(v.min == Version(string: "1.0.1"))
        XCTAssert(v.max == Version(string: "2.0.0"))
        XCTAssert(v.minInclusive == false)
        XCTAssert(v.maxInclusive == false)
        XCTAssert(v.description == ">1.0.1, <2.0.0")
    }

    func testCombineMultipleUpper() throws {
        let v = VersionRange(versionString: ">1.0.1")
        try v.combine("<=2.0.0")
        try v.combine("<1.9.0")
        try v.combine("<3.0.0")
        try v.combine("<=2.1.0")
        XCTAssert(v.min == Version(string: "1.0.1"))
        XCTAssert(v.max == Version(string: "1.9.0"))
        XCTAssert(v.minInclusive == false)
        XCTAssert(v.maxInclusive == false)
        XCTAssert(v.description == ">1.0.1, <1.9.0")
    }

    func testCombineMultipleLower() throws {
        let v = VersionRange(versionString: "<2.0.0")
        try v.combine(">=1.0.1")
        try v.combine(">1.5.0")
        try v.combine(">0.9.0")
        try v.combine(">=0.8.0")
        XCTAssert(v.min == Version(string: "1.5.0"))
        XCTAssert(v.max == Version(string: "2.0.0"))
        XCTAssert(v.minInclusive == false)
        XCTAssert(v.maxInclusive == false)
        XCTAssert(v.description == ">1.5.0, <2.0.0")
    }

    func testCombineEqual() throws {
        let v = VersionRange(versionString: "<2.0.0")
        try v.combine(">=1.0.1")
        try v.combine("==1.5.0")
        XCTAssert(v.min == Version(string: "1.5.0"))
        XCTAssert(v.max == Version(string: "1.5.0"))
        XCTAssert(v.minInclusive == true)
        XCTAssert(v.maxInclusive == true)
        XCTAssert(v.description == "==1.5.0")
    }

    // MARK: - Invalid combination tests
    func testCombineFailLower() throws {
        let v = VersionRange(versionString: "<2.0.0")
        try v.combine(">1.0.0")
        do {
            try v.combine("<1.0.0")
            XCTFail("Invalid combination should throw")
        } catch {
            // expected
        }
    }

    func testCombineFailUpper() throws {
        let v = VersionRange(versionString: "<2.0.0")
        try v.combine(">1.0.0")
        do {
            try v.combine(">2.0.0")
            XCTFail("Invalid combination should throw")
        } catch {
            // expected
        }
    }

    func testCombineFailLowerEqual() throws {
        let v = VersionRange(versionString: "<2.0.0")
        try v.combine(">=1.0.0")
        do {
            try v.combine("<1.0.0")
            XCTFail("Invalid combination should throw")
        } catch {
            // expected
        }
    }

    func testCombineFailUpperEqual() throws {
        let v = VersionRange(versionString: "<=2.0.0")
        try v.combine(">1.0.0")
        do {
            try v.combine(">2.0.0")
            XCTFail("Invalid combination should throw")
        } catch {
            // expected
        }
    }

    func testCombineFailEqualTooLow() throws {
        let v = VersionRange(versionString: "<2.0.0")
        try v.combine(">1.0.0")
        do {
            try v.combine("==0.9.0")
            XCTFail("Invalid combination should throw")
        } catch {
            // expected
        }
    }

    func testCombineFailEqualTooBig() throws {
        let v = VersionRange(versionString: "<2.0.0")
        try v.combine(">1.0.0")
        do {
            try v.combine("==2.1.0")
            XCTFail("Invalid combination should throw")
        } catch {
            // expected
        }
    }
}

extension VersionRangeTests {
    static var allTests : [(String, VersionRangeTests -> () throws -> Void)] {
        return [
            ("testInitSimple",       testInitSimple),
            ("testInitSmaller",      testInitSmaller),
            ("testInitBigger",       testInitBigger),
            ("testInitSmallerEqual", testInitSmallerEqual),
            ("testInitBiggerEqual",  testInitBiggerEqual),
            ("testInitEqual",        testInitEqual),

            ("testCombineWithLowerBound", testCombineWithLowerBound),
            ("testCombineWithUpperBound", testCombineWithUpperBound),
            ("testCombineMultipleUpper",  testCombineMultipleUpper),
            ("testCombineMultipleLower",  testCombineMultipleLower),
            ("testCombineEqual",          testCombineEqual),

            ("testCombineFailLower",       testCombineFailLower),
            ("testCombineFailUpper",       testCombineFailUpper),
            ("testCombineFailLowerEqual",  testCombineFailLowerEqual),
            ("testCombineFailUpperEqual",  testCombineFailUpperEqual),
            ("testCombineFailEqualTooLow", testCombineFailEqualTooLow),
            ("testCombineFailEqualTooBig", testCombineFailEqualTooBig),
        ]
    }
}