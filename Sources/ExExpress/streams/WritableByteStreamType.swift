//
//  WritableByteStreamType.swift
//  ExExpress
//
//  Created by Helge Hess on 07/02/17.
//  Copyright © 2017-2019 ZeeZide GmbH. All rights reserved.
//

import struct Foundation.Data

public protocol WritableByteStreamType : WritableStreamType {
  
  // FIXME: may want to default to Data or better DispatchData
  func writev(buckets chunks: [ [ UInt8 ] ], done: DoneCB?) throws
  
}

// MARK: - UTF8 support for UInt8 streams

// Well, yes. :-) This is all due to generic-protocols-are-not-a-type. We might
// want to define the methods on both, but then we can end up with ambiguities
// as many objects do implement both?!
//
// public extension GWritableStreamType where WriteType == UInt8 {}
/// Convenience - can write Strings to any Byte stream as UTF-8
//public extension GWritableStreamType where WriteType == UInt8 {
public extension WritableByteStreamType {
  // TODO: UTF8View should be a BucketType ...
  
  func write(_ chunk: String, done: DoneCB? = nil) throws {
    let bucket = Array<UInt8>(chunk.utf8) // aaargh
    try writev(buckets: [ bucket ], done: done)
  }
  
  func write(_ chunk: Data, done: DoneCB? = nil) throws {
    let bucket = Array<UInt8>(chunk) // aargh
    try writev(buckets: [ bucket ], done: done)
  }
  
  func end(_ chunk: [ UInt8 ]? = nil, doneWriting: DoneCB? = nil) throws {
    if let chunk = chunk {
      try writev(buckets: [ chunk ]) {
        if let cb = doneWriting { try cb() }
        try self.end() // only end after everything has been written
      }
    }
    else {
      if let cb = doneWriting { try cb() } // nothing to write, immediately done
      try end()
    }
  }
  
  func end(_ chunk: String, doneWriting: DoneCB? = nil) throws {
    let bucket = Array<UInt8>(chunk.utf8) // aaargh
    try writev(buckets: [ bucket ]) {
      if let cb = doneWriting { try cb() }
      try self.end()
    }
  }
  func end(_ chunk: Data, doneWriting: DoneCB? = nil) throws {
    let bucket = Array<UInt8>(chunk) // aaargh
    try writev(buckets: [ bucket ]) {
      if let cb = doneWriting { try cb() }
      try self.end()
    }
  }
}
