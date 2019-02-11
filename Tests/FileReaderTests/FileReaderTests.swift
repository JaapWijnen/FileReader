import XCTest
@testable import FileReader

final class FileReaderTests: XCTestCase {
    func testFileRead() throws {

    }
    
    func testStringRead() throws {
        let string = "test1\ntest2"
        let fileReader = try FileReader(string: string)
        let firstLine = fileReader.readLine()
        XCTAssertEqual(firstLine, "test1")
        let secondLine = fileReader.readLine()
        XCTAssertEqual(secondLine, "test2")
        let thirdLine = fileReader.readLine()
        XCTAssertNil(thirdLine)
    }

    static var allTests = [
        ("testFileRead", testFileRead),
        ("testStringRead", testStringRead),
        
    ]
}
