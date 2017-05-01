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
  
  public static func parse(_ string       : String,
                           separator      : Character = "&",
                           pairSeparator  : Character = "=",
                           depth          : Int       = 5,
                           parameterLimit : Int       = 1000,
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
