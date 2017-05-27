//
//  Stringify.swift
//  Noze.io
//
//  Created by Helge Hess on 10/06/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

// TODO: indent, replacer:
//   https://developer.mozilla.org/de/docs/Web/JavaScript/Reference/Global_Objects/JSON/stringify

public extension JSON {
  
  public static func stringify(_ object: Any?) -> Swift.String {
    guard let o = object else { return "null" }
    
    if let json = o as? JSON {
      return json.toString()
    }
    
    if let encodable = o as? JSONEncodable {
      return encodable.toJSON().toString()
    }
    
    return JSON.string(String(describing: o)).toString()
  }
  
  public func toString() -> Swift.String {
    var jsonString = ""
    jsonString.appendJSON(object: self)
    return jsonString
  }
  
}

public extension String {

  public mutating func appendJSON(string s: String) {
    let chars = s.characters
    reserveCapacity(chars.count + 2)
    
    self += "\""
    
    // Naive, Naive, make much faster
    for c in chars {
      let quote : Bool
      var cc    : Character = c
      
      switch c {
        case "\"":  quote = true
        case "\\": quote = true
        // case 0x2F: quote = true // /
        case "\u{08}": quote = true; cc = "b"
        case "\u{0C}": quote = true; cc = "f"
        case "\n": quote = true; cc = "n"
        case "\r": quote = true; cc = "r"
        case "\t": quote = true; cc = "t"
        // TBD: %x75 4HEXDIG )  ; uXXXX                U+XXXX
        default:   quote = false
      }
      
      if quote { self += "\\" }
      append(cc)
    }
    
    self += "\""
  }
  
  public mutating func appendJSON(object o: JSON) {
    switch o {
      case .int   (let v): self += "\(v)"
      case .string(let v): appendJSON(string: v)
      
      case .array(let children):
        self += "[ "
        do {
          var isFirst = true
          for child in children {
            if isFirst { isFirst = false }
            else { self += ", " }
            
            appendJSON(object: child)
          }
        }
        self += " ]"
      
      case .dictionary(let object):
        self += "{ "
        do {
          var isFirst = true
          for ( key, child ) in object {
            if isFirst { isFirst = false }
            else { self += ", " }
            
            appendJSON(string: key)
            self += ": "
            
            appendJSON(object: child)
          }
        }
        self += " }"
      
      case .double(let v):
        self += "\(v)" // FIXME: quite likely wrong
          
      case .bool(let v):
        self += v ? "true" : "false"
      
      case .null:
        self += "null"
    }
  }

}
