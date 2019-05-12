//
//  JSON.swift
//  Noze.io
//
//  Created by Helge Heß on 6/3/16.
//  Copyright © 2016-2019 ZeeZide GmbH. All rights reserved.
//

public extension ServerResponse {
  // TODO: add jsonp
  // TODO: be a proper stream
  // TODO: Maybe we don't want to convert to a `JSON`, but rather stream real
  //       object.
  
  func json(_ object: JSON) throws {
    if canAssignContentType {
      setHeader("Content-Type", "application/json; charset=utf-8")
    }
    try writeJSON(object: object)
    try end()
  }
}


// MARK: - Helpers

public extension ServerResponse {

  func json(_ object: JSONEncodable) throws {
    try json(object.toJSON())
  }
  
  func json(_ object: Any?) throws {
    if let o = object {
      if let jsonEncodable = (o as? JSONEncodable) {
        try json(jsonEncodable)
      }
      else if let jsonEnum = (o as? JSON) {
        try json(jsonEnum)
      }
      else {
        // TODO: really throw. Or send some error
        console.error("cannot JSON encode object:", o)
        try json(.null)
      }
    }
    else {
      try json(.null)
    }
  }
}

