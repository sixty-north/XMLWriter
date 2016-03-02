//
//  XMLWriterTests.swift
//  XMLWriterTests
//
//  Created by Robert Smallshire on 2/3/16.
//  Copyright © 2016 Sixty North. All rights reserved.
//

import XCTest
@testable import XMLWriter

class XMLWriterTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testZeroRootElementsInDocument() {
        // XML documents must have exactly one root element
        let stream = OutputStringStream()
        do {
            let writer = XMLWriter.createDocument(stream)
            try writer.close()
            XCTFail("No exception raised: Expected TooFewRootElements")
        }
        catch XMLWriterError.TooFewRootElements {
            // Expected
        }
        catch let error {
            XCTFail("Wrong exception type \(error) raised: Expected TooFewRootElements")
        }
    }
    
    func testOneRootElementInDocument() {
        // XML documents must have exactly one root element
        let stream = OutputStringStream()
        do {
            let writer = XMLWriter.createDocument(stream)
            try writer.startElement("root")
            try writer.endElement()
            try writer.close()
        }
        catch let error {
            XCTFail("Unexpected exception: \(error)")
        }
        XCTAssertEqual(stream.string, "<?xml version=\"1.0\" encoding=\"utf-8\" ?><root />")
    }
    
    func testTwoRootElementsInDocument() {
        // XML documents must have exactly one root element
        let stream = OutputStringStream()
        do {
            let writer = XMLWriter.createDocument(stream)
            try writer.startElement("root1")
            try writer.endElement()
            try writer.startElement("root2")
            try writer.endElement()
            try writer.close()
            XCTFail("No exception raised: Expected TooManyRootElements")
        }
        catch XMLWriterError.TooManyRootElements {
            // Expected
        }
        catch let error {
            XCTFail("Wrong exception type \(error) raised: Expected TooManyRootElements")
        }
    }
}
