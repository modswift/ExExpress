//
//  JsonFile.swift
//  Noze.io
//
//  Created by Helge Hess on 10/06/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import struct Foundation.Data

public class JsonFileModule {
  
  public enum Error : Swift.Error {
    case GotNoData
  }
  
  
  // MARK: - Reading
  
  public func readFile(_ path: String,
                       cb: @escaping ( Swift.Error?, JSON? ) -> Void)
  {
    fs.readFile(path) { err, bytes in
      guard err == nil       else { cb(err,             nil); return }
      guard let utf8 = bytes else { cb(Error.GotNoData, nil); return }
      
      do {
        let obj : JSON = try utf8.withUnsafeBufferPointer { p in
          let data = Data(buffer: p)
          return try JSONParser.parse(utf8: data)
        }
        cb(nil, obj)
      }
      catch let error {
        cb(error, nil)
      }
    }
  }
  
  public func readFileSync(_ path: String, throws t: Bool=true) throws -> JSON?{
    // read file synchronously
    let bytes = fs.readFileSync(path)
    
    // check whether that worked
    guard let utf8 = bytes else {
      if t { throw(Error.GotNoData) }
      else { return nil }
    }
    
    // and parse synchronously
    do {
      let obj : JSON = try utf8.withUnsafeBufferPointer { p in
        let data = Data(buffer: p)
        return try JSONParser.parse(utf8: data)
      }
      return obj
    }
    catch let error {
      if t { throw(error) }
      else { return nil }
    }
  }
  public func readFileSync(_ path: String) -> JSON? {
    return try! readFileSync(path, throws: false)
  }
  
}

public let jsonfile = JsonFileModule()
