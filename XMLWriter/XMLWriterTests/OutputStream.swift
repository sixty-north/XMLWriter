//
//  OutputStream.swift
//  PurpleSwift
//
//  Created by Erica Sadun on 7/2/15.
//  Copyright © 2015 Erica Sadun. All rights reserved.
//

import Foundation

public class OutputStream : OutputStreamType {
    let stream : UnsafeMutablePointer<FILE> // Selected stream
    var path : NSString? = nil // File path
    
    // Create with stream
    public init(_ stream: UnsafeMutablePointer<FILE>) {
        self.stream = stream
    }
    
    // Create with output file
    public init?(path : String, append : Bool = false) {
        if (append) {
            stream = fopen(path, "a")
        } else {
            stream = fopen(path, "w")
        }
        if stream == nil {return nil}
        self.path = path
    }
    
    // stderr
    public static func stderr() -> OutputStream {
        return OutputStream(Darwin.stderr)
    }
    
    // stdout
    public static func stdout() -> OutputStream {
        return OutputStream(Darwin.stdout)
    }
    
    // Conform to OutputStreamType
    public func write(string: String) {
        fputs(string, stream)
    }
    
    // Clean up open FILE
    deinit {
        if path != nil {fclose(stream)}
    }
}