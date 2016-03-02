//
//  OutputStringStream.swift
//  XMLWriter
//
//  Created by Robert Smallshire on 2/3/16.
//  Copyright © 2016 Sixty North. All rights reserved.
//

import Foundation

//
//  OutputStream.swift
//  PurpleSwift
//
//  Created by Erica Sadun on 7/2/15.
//  Copyright © 2015 Erica Sadun. All rights reserved.
//

import Foundation

public class OutputStringStream : OutputStreamType {
    var fragments: [String]
    
    // Create with stream
    public init() {
        self.fragments = []
    }
    
    // Conform to OutputStreamType
    public func write(string: String) {
        fragments.append(string)
    }
    
    public var string: String {
        let joined = fragments.joinWithSeparator("")
        fragments.removeAll()
        fragments.append(joined)
        return joined
    }
}