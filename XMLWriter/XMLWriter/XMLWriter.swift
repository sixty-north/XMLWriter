//
//  XMLWriter.swift
//
//  Created by Robert Smallshire on 28/2/16.
//  Copyright © 2016 Sixty North AS. All rights reserved.
//

import Foundation

public enum XMLWriterError : ErrorType {
    case BadHierarchy
    case MismatchedEnd
    case StackUnderflow
    case InvalidComment
    case TooFewRootElements
    case TooManyRootElements
    case NonWhitespaceTextAtDocumentRoot
}

protocol XMLWriterState
{
    func startElement(name: String) throws
    func endElement() throws
    func startAttribute(name: String) throws
    func endAttribute() throws
    func startComment() throws
    func endComment() throws
    func startProcessingInstruction(target: String) throws
    func endProcessingInstruction() throws
    func startCData() throws
    func endCData() throws
    func writeText(text: String) throws
    
    func enter() throws
    func exit() throws
}


class FragmentState : XMLWriterState {
    
    unowned let writer: XMLWriter
    
    init(writer: XMLWriter) {
        self.writer = writer
    }
    
    func startElement(name: String) throws {
        try writer.push(ElementState(writer: writer, name: name))
    }
    
    func endElement() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startAttribute(name: String) throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func endAttribute() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startComment() throws {
        try writer.push(CommentState(writer: writer))
    }
    
    func endComment() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startProcessingInstruction(target: String) throws {
        try writer.push(ProcessingInstructionState(writer: writer, target: target))
    }
    
    func endProcessingInstruction() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startCData() throws {
        try writer.push(CDataState(writer: writer))
    }
    
    func endCData() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func writeText(text: String) throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func enter() throws {
        // no-op
    }
    
    func exit() throws {
        // no-op
    }
}

class DocumentState : XMLWriterState {
    
    unowned let writer: XMLWriter
    
    var numRootElements: Int
    
    init(writer: XMLWriter) {
        self.writer = writer
        self.numRootElements = 0
    }
    
    func startElement(name: String) throws {
        try ensureSingleRootElement()
        try writer.push(ElementState(writer: writer, name: name))
    }
    
    func endElement() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startAttribute(name: String) throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func endAttribute() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startComment() throws {
        try writer.push(CommentState(writer: writer))
    }
    
    func endComment() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startProcessingInstruction(target: String) throws {
        try writer.push(ProcessingInstructionState(writer: writer, target: target))
    }
    
    func endProcessingInstruction() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startCData() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func endCData() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func writeText(text: String) throws {
        guard text.isEmptyOrWhiteSpace() else {
            throw XMLWriterError.NonWhitespaceTextAtDocumentRoot
        }
        writer.writeRaw(text)
    }
    
    func enter() throws {
        writer.writeRaw("<?xml version=\"1.0\" encoding=\"utf-8\" ?>")
    }
    
    func exit() throws {
        if numRootElements < 1 {
            throw XMLWriterError.TooFewRootElements
        }
    }
    
    func ensureSingleRootElement() throws {
        ++numRootElements
        if numRootElements > 1 {
            throw XMLWriterError.TooManyRootElements
        }
    }
}

class ElementState : XMLWriterState {
    
    unowned let writer: XMLWriter
    let name: String
    var isEmpty: Bool
    
    init(writer: XMLWriter, name: String) {
        self.writer = writer
        self.name = name
        self.isEmpty = true
    }
    
    func startElement(name: String) throws
    {
        ensureStartTagClosed()
        try writer.push(ElementState(writer: writer, name: name))
    }
    
    func endElement() throws
    {
        try writer.pop()
    }
    
    func startAttribute(name: String) throws {
        if !isEmpty {
            throw XMLWriterError.BadHierarchy
        }
        try writer.push(AttributeState(writer: writer, name: name))
    }
    
    func endAttribute() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startComment() throws {
        ensureStartTagClosed()
        try writer.push(CommentState(writer: writer))
    }
    
    func endComment() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startProcessingInstruction(target: String) throws {
        ensureStartTagClosed()
        try writer.push(ProcessingInstructionState(writer: writer, target: target))
    }
    
    func endProcessingInstruction() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startCData() throws {
        ensureStartTagClosed()
        try writer.push(CDataState(writer: writer))
    }
    
    func endCData() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func enter() throws {
        writeOpenStartTag()
    }
    
    func exit() throws {
        if isEmpty {
            writeCloseStartTagAsEmptyElement()
        }
        else {
            writeEndTag()
        }
    }
    
    func writeText(text: String) throws {
        ensureStartTagClosed()
        let escapedText = writer.escapeText(text)
        writer.writeRaw(escapedText)
    }
    
    func writeOpenStartTag() {
        writer.writeRaw("<\(name)")
    }
    
    func writeCloseStartTag() {
        writer.writeRaw(">")
    }
    
    func writeCloseStartTagAsEmptyElement() {
        writer.writeRaw(" />")
    }
    
    func writeEndTag() {
        writer.writeRaw("</\(name)>")
    }
    
    func ensureStartTagClosed() {
        if isEmpty {
            writeCloseStartTag()
            isEmpty = false
        }
    }
}

class AttributeState : XMLWriterState {
    
    unowned let writer: XMLWriter
    let name: String
    
    init(writer: XMLWriter, name: String) {
        self.writer = writer
        self.name = name
    }
    
    func startElement(name: String) throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func endElement() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startAttribute(name: String) throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startComment() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func endComment() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func endAttribute() throws {
        try writer.pop()
    }
    
    func startProcessingInstruction(target: String) throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func endProcessingInstruction() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startCData() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func endCData() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func writeText(text: String) throws {
        let escapedText = writer.escapeText(text)
        writer.writeRaw(escapedText)
    }
    
    func enter() throws {
        writer.writeRaw(" \(name)=\"")
    }
    
    func exit() throws {
        writer.writeRaw("\"")
    }
}

class CommentState : XMLWriterState {
    
    unowned let writer: XMLWriter
    var previousTerminatedWithHyphen: Bool
    
    init(writer: XMLWriter) {
        self.writer = writer
        self.previousTerminatedWithHyphen = false
    }
    
    func startElement(name: String) throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func endElement() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startAttribute(name: String) throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func endAttribute() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startComment() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func endComment() throws {
        try writer.pop()
    }
    
    func startProcessingInstruction(target: String) throws {
        try writer.push(ProcessingInstructionState(writer: writer, target: target))
    }
    
    func endProcessingInstruction() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startCData() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func endCData() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func writeText(text: String) throws {
        if previousTerminatedWithHyphen && text.hasPrefix("-") {
            throw XMLWriterError.InvalidComment
        }
        
        if text.containsString("--") {
            throw XMLWriterError.InvalidComment
        }
        
        previousTerminatedWithHyphen = text.hasSuffix("-")
        writer.writeRaw(text)
    }
    
    func enter() throws {
        writer.writeRaw("<!--")
    }
    
    func exit() throws {
        writer.writeRaw("-->")
    }
    
}

class ProcessingInstructionState : XMLWriterState {
    
    unowned let writer: XMLWriter
    let target: String
    
    init(writer: XMLWriter, target: String) {
        self.writer = writer
        self.target = target
    }
    
    func startElement(name: String) throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func endElement() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startAttribute(name: String) throws {
        try writer.push(AttributeState(writer: writer, name: name))
    }
    
    func endAttribute() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startComment() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func endComment() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startProcessingInstruction(target: String) throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func endProcessingInstruction() throws {
        try writer.pop()
    }
    
    func startCData() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func endCData() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func writeText(text: String) throws {
        // TODO: Validate text according to rules for processing instructions
        // TODO: Escape text according to rules for processing instructions
        writer.writeRaw(text)
    }
    
    func enter() throws {
        writer.writeRaw("<?\(target)")
    }
    
    func exit() throws {
        writer.writeRaw("?>")
    }
}

class CDataState : XMLWriterState {
    
    unowned let writer: XMLWriter
    
    init(writer: XMLWriter) {
        self.writer = writer
    }
    
    func startElement(name: String) throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func endElement() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startAttribute(name: String) throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func endAttribute() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startComment() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func endComment() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startProcessingInstruction(target: String) throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func endProcessingInstruction() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func startCData() throws {
        throw XMLWriterError.BadHierarchy
    }
    
    func endCData() throws {
        try writer.pop()
    }
    
    func writeText(text: String) throws {
        // TODO: We need to retain sufficient memory to identify "]]>" sequences, even if
        // they are split across three calls to this method, and replace them with
        // "]]]]><![CDATA[>" effectively splitting the unencodable data across two CDATA
        // elements
        let sanitizedText = text.stringByReplacingOccurrencesOfString("]]>", withString: "]]]]><![CDATA[>")
        writer.writeRaw(sanitizedText)
    }
    
    func enter() throws {
        writer.writeRaw("<![CDATA[")
    }
    
    func exit() throws {
        writer.writeRaw("]]>")
    }
}

public class XMLWriter {
    
    var stream: OutputStreamType
    
    private var stack: [XMLWriterState]
    
    public class func createDocument(stream: OutputStreamType) -> XMLWriter {
        let writer = self.init(stream: stream)
        try! writer.push(DocumentState(writer: writer))
        return writer
    }
    
    public class func createFragment(stream: OutputStreamType) -> XMLWriter {
        let writer = self.init(stream: stream)
        try! writer.push(FragmentState(writer: writer))
        return writer
    }
    
    public required init(stream: OutputStreamType) {
        self.stream = stream
        self.stack = []
    }
    
    deinit {
        try! close()
    }
    
    private func top() throws -> XMLWriterState {
        if let state = stack.last {
            return state
        }
        else {
            throw XMLWriterError.StackUnderflow
        }
    }
    
    private func push(state: XMLWriterState) throws {
        try state.enter()
        stack.append(state)
    }
    
    private func pop() throws -> XMLWriterState {
        if let state = stack.popLast() {
            try state.exit()
            return state
        }
        else {
            throw XMLWriterError.StackUnderflow
        }
    }
    
    public func startElement(name: String) throws {
        try top().startElement(name)
    }
    
    public func endElement() throws {
        try top().endElement()
    }
    
    public func startAttribute(name: String) throws {
        try top().startAttribute(name)
    }
    
    public func endAttribute() throws {
        try top().endAttribute()
    }
    
    public func startComment() throws {
        try top().startComment()
    }
    
    public func endComment() throws {
        try top().endComment()
    }
    
    public func startProcessingInstruction(target: String) throws {
        try top().startProcessingInstruction(target)
    }
    
    public func endProcessingInstruction() throws {
        try top().endProcessingInstruction()
    }
    
    public func writeText(text: String) throws {
        try top().writeText(text)
    }
    
    public func writeRaw(text: String) {
        stream.write(text)
    }
    
    public func close() throws {
        while let state = stack.popLast() {
            try state.exit()
        }
    }
    
    func escapeText(text: String) -> String {
        let xmlEntities : [Character: String] = [
            "<" : "&lt;",
            "&" : "&amp;",
            ">" : "&gt;",
            "'" : "&apos;",
            "\"": "&quot;"]
        
        return translate(text, table: xmlEntities)
    }
    
    func translate(text: String, table: [Character: String]) -> String {
        let fragments = text.characters.map {table[$0] ?? String($0)}
        return String(fragments.flatMap {String.CharacterView($0)})
    }
}

extension String {
    func isEmptyOrWhiteSpace() -> Bool {
        if self.isEmpty {
            return true
        }
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).isEmpty
    }
}