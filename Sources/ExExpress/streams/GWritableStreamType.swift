//
//  GWritableStreamType.swift
//  ExExpress
//
//  Created by Helge Hess on 07/02/17.
//  Copyright © 2017-2022 ZeeZide GmbH. All rights reserved.
//

public protocol GWritableStreamType : AnyObject, WritableStreamType {
  
  associatedtype WriteType
  
  func writev(buckets b: [ [ WriteType ] ], done: DoneCB?) throws
}


// MARK: - Extensions

public extension GWritableStreamType {
  
  func write(_ chunk: [ WriteType ], done: DoneCB? = nil) throws {
    try writev(buckets: [ chunk ], done: done )
  }
  
  func end(_ chunk: [ WriteType ]? = nil, doneWriting: DoneCB? = nil) throws {
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
}
