//
//  QS.swift
//  ExExpress
//
//  Created by Helge Hess on 02.05.17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

public enum qs {
  // TODO: doesn't really belong here, but well.
  // TODO: stringify etc
  // TODO: this is a little funky because URL parsing really happens at a byte
  //       level (% decoding etc)
  
  struct Options {
    let separator      : Character = "&"
    let pairSeparator  : Character = "="
    let depth          : Int       = 5
    let parameterLimit : Int       = 1000
    let arrayLimit     : Int       = 20
    let allowsDot      : Bool      = false
  }
  
  public static func parse(_ string       : String,
                           separator      : Character = "&",
                           pairSeparator  : Character = "=",
                           depth          : Int       = 5,
                           parameterLimit : Int       = 1000,
                           arrayLimit     : Int       = 20,
                           allowsDot      : Bool      = false)
                     -> Dictionary<String, Any>
  {
    if allowsDot { fatalError("allowsDot unsupported") }
    
    let qv = querystring.parse(string,
                               separator: separator,
                               pairSeparator: pairSeparator)
    
    // TODO: do the 'abc[def]' decoding thing
    
    return qv
  }
}

// 'foo[bar][baz]=foobarbaz' -> [ "foo": [ "bar": [ "baz": "foobarbaz" ] ] ]
// 'a[]=b&a[]=c')            -> [ "a": [ "b", "c" ] ]
// 'a[1]=b&a[3]=c'           -> [ "a": [ nil, "b", nil, "c" ] ]  (max: 20)
// 'a.b=c' (allowsDot)       -> [ "a": [ "b": "c" ] ]
enum QueryParameterKeyPart {
  case Key(String) // hello or [hello]
  case Index(Int)  // [1]
}
