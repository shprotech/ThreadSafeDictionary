import XCTest
@testable import ThreadSafeDictionary

final class ThreadSafeDictionaryTests: XCTestCase {
    func testInsertions() async throws {
        let dict = ThreadSafeDictionary<String, String>()
        var data = await dict.data
        XCTAssertEqual([:], data)
        await dict.set("hello", to: "world")
        
        data = await dict.data
        XCTAssertEqual(["hello": "world"], data)
    }
    
    func testCopy() async throws {
        let dict = ThreadSafeDictionary<String, String>()
        await dict.set("hello", to: "world")
        let copy = await dict.copy()
        
        XCTAssertNotIdentical(dict, copy)
        
        var originalData = await dict.data
        var copyData = await copy.data
        
        XCTAssertEqual(originalData, copyData)
        
        await dict.set("hey", to: "you")
        
        originalData = await dict.data
        copyData = await copy.data
        
        XCTAssertNotEqual(originalData, copyData)
        XCTAssertNotIdentical(dict, copy)
    }
}
