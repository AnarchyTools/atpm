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
class VersionTests: XCTestCase {
    func testParse1() {
    	let v = Version(string: "1.2.3b1")
        XCTAssert(v.major == 1)
        XCTAssert(v.minor == 2)
        XCTAssert(v.patch == 3)
        XCTAssert(v.ext == "b1")
    }
    func testParse2() {
    	let v = Version(string: "v1.2.3b1")
        XCTAssert(v.major == 1)
        XCTAssert(v.minor == 2)
        XCTAssert(v.patch == 3)
        XCTAssert(v.ext == "b1")
    }
    func testParse3() {
    	let v = Version(string: "V1.2.3b1")
        XCTAssert(v.major == 1)
        XCTAssert(v.minor == 2)
        XCTAssert(v.patch == 3)
        XCTAssert(v.ext == "b1")
    }
    func testParse4() {
    	let v = Version(string: "1.2")
        XCTAssert(v.major == 1)
        XCTAssert(v.minor == 2)
        XCTAssert(v.patch == 0)
        XCTAssert(v.ext == "")
    }
    func testParse5() {
    	let v = Version(string: "1.2.3")
        XCTAssert(v.major == 1)
        XCTAssert(v.minor == 2)
        XCTAssert(v.patch == 3)
        XCTAssert(v.ext == "")
    }
    func testParse6() {
    	let v = Version(string: "1.2b1")
        XCTAssert(v.major == 1)
        XCTAssert(v.minor == 2)
        XCTAssert(v.patch == 0)
        XCTAssert(v.ext == "b1")
    }
    func testParse7() {
    	let v = Version(string: "101.299.331-hnofclbri")
        XCTAssert(v.major == 101)
        XCTAssert(v.minor == 299)
        XCTAssert(v.patch == 331)
        XCTAssert(v.ext == "-hnofclbri")
    }

    func testEqual1() {
    	let v1 = Version(string: "1.2")
    	let v2 = Version(string: "1.2.0")
        XCTAssert(v1 == v2)
    }
    func testEqual2() {
    	let v1 = Version(string: "1.2")
    	let v2 = Version(string: "1.2.1")
        XCTAssert(v1 != v2)
    }
    func testEqual3() {
    	let v1 = Version(string: "1.2")
    	let v2 = Version(string: "1.3")
        XCTAssert(v1 != v2)
    }
    func testEqual4() {
    	let v1 = Version(string: "1.2")
    	let v2 = Version(string: "2.2")
        XCTAssert(v1 != v2)
    }
    func testEqual5() {
    	let v1 = Version(string: "1.2")
    	let v2 = Version(string: "1.2b1")
        XCTAssert(v1 != v2)
    }

    func testGreater1() {
    	let v1 = Version(string: "1.2")
    	let v2 = Version(string: "1.2.1")
        XCTAssert(v2 > v1)
    }
    func testGreater2() {
    	let v1 = Version(string: "1.2")
    	let v2 = Version(string: "1.3")
        XCTAssert(v2 > v1)
    }
    func testGreater3() {
    	let v1 = Version(string: "1.2")
    	let v2 = Version(string: "2.2")
        XCTAssert(v2 > v1)
    }
    func testGreater4() {
    	let v1 = Version(string: "1.2rc1")
    	let v2 = Version(string: "1.2")
        XCTAssert(v2 > v1)
    }


    func testSmaller1() {
    	let v1 = Version(string: "1.2")
    	let v2 = Version(string: "1.2.1")
        XCTAssert(v1 < v2)
    }
    func testSmaller2() {
    	let v1 = Version(string: "1.2")
    	let v2 = Version(string: "1.3")
        XCTAssert(v1 < v2)
    }
    func testSmaller3() {
    	let v1 = Version(string: "1.2")
    	let v2 = Version(string: "2.2")
        XCTAssert(v1 < v2)
    }
    func testSmaller4() {
    	let v1 = Version(string: "1.2rc1")
    	let v2 = Version(string: "1.2")
        XCTAssert(v1 < v2)
    }

    func testStringConvertible1() {
    	let v = Version(string: "1.2.3rc1")
        XCTAssert("\(v)" == "1.2.3rc1")
    }
    func testStringConvertible2() {
    	let v = Version(string: "1.2rc1")
        XCTAssert("\(v)" == "1.2rc1")
    }
    func testStringConvertible3() {
    	let v = Version(string: "1.2")
        XCTAssert("\(v)" == "1.2")
    }

}

extension VersionTests: XCTestCaseProvider {
    var allTests : [(String, () -> Void)] {
        return [
            ("testParse1", testParse1),
            ("testParse2", testParse2),
            ("testParse3", testParse3),
            ("testParse4", testParse4),
            ("testParse5", testParse5),
            ("testParse6", testParse6),
            ("testParse7", testParse7),

            ("testEqual1", testEqual1),
            ("testEqual2", testEqual2),
            ("testEqual3", testEqual3),
            ("testEqual4", testEqual4),
            ("testEqual5", testEqual5),

            ("testGreater1", testGreater1),
            ("testGreater2", testGreater2),
            ("testGreater4", testGreater4),
            ("testGreater3", testGreater3),

            ("testSmaller1", testSmaller1),
            ("testSmaller2", testSmaller2),
            ("testSmaller3", testSmaller3),
            ("testSmaller4", testSmaller4),

            ("testStringConvertible1", testStringConvertible1),
            ("testStringConvertible2", testStringConvertible2),
            ("testStringConvertible3", testStringConvertible3)
        ]
    }
}