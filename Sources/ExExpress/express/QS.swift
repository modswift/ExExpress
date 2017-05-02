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
  
  public class Options {
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
// 'a[][b]=c'                -> [ "a": [ [ "b": "c" ] ] ]
enum QueryParameterKeyPart {
  case Key(String) // hello or [hello]
  case Index(Int)  // [1]
  case Array       // []
  case Error(String)
}

extension qs {
  
  static func parseKeyPath(_ s: String, depth: Int = 5, allowsDot: Bool)
              -> [ QueryParameterKeyPart ]
  {
    guard !s.isEmpty else { return [] }
    
    var idx      = s.startIndex
    let endIndex = s.endIndex
    
    func consume(_ count: Int = 1) {
      idx = s.index(idx, offsetBy: count)
    }
    func isDigit(_ c: Character) -> Bool {
      switch c {
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9": return true
        default: return false
      }
    }
    
    func parseIdentifier() -> String? {
      guard idx < endIndex else { return nil }
      
      var hitDot = false
      var lidx = idx
      while lidx < endIndex {
        if allowsDot && s[lidx] == "." {
          hitDot = true
          break
        }
        if s[lidx] == "[" {
          break
        }
        
        lidx = s.index(after: lidx)
      }
      
      if hitDot {
        let r = s[idx..<lidx]
        idx = s.index(after: lidx)
        return r
      }
      
      let r = s[idx..<lidx]
      idx = lidx
      return r
    }
    
    func parseNumber() -> Int? {
      guard idx < endIndex else { return nil }
      
      var lidx = idx
      while lidx < endIndex {
        guard isDigit(s[lidx]) else { break }
        lidx = s.index(after: lidx)
      }
      
      let sv = s[idx..<lidx]
      idx = lidx
      
      return Int(sv)
    }
    
    func parseSubscript() -> QueryParameterKeyPart? {
      guard idx < endIndex else { return nil }
      guard s[idx] == "["  else { return nil }
      
      consume() // "["
      guard idx < endIndex else { return .Error("lbrack not closed") }
      
      if s[idx] == "]" {
        consume() // ]
        return .Array
      }
      
      if isDigit(s[idx]) {
        guard let v = parseNumber()
         else { return .Error("could not parse number") }
        guard idx < endIndex, s[idx] == "]"
         else { return .Error("lbrack not closed") }
        
        consume() // ]
        return .Index(v)
      }
      
      var lidx = idx
      while lidx < endIndex {
        if s[lidx] == "]" { break }
        lidx = s.index(after: lidx)
      }
      guard lidx < endIndex, s[lidx] == "]"
       else { return .Error("lbrack not closed") }
      
      let r = s[idx..<lidx]
      idx = s.index(after: lidx)
      
      return .Key(r)
    }
    
    func parseKeyPart() -> QueryParameterKeyPart? {
      guard idx < endIndex else { return nil }
      
      if s[idx] == "[" {
        return parseSubscript()
      }
      
      guard let kid = parseIdentifier() else { return nil }
      return .Key(kid)
    }
    
    var parts = [ QueryParameterKeyPart ]()
    while let part = parseKeyPart() {
      parts.append(part)
      
      // check depth limit.
      if parts.count > depth {
        if idx < endIndex {
          parts.append(.Key(s[idx..<endIndex]))
        }
        break
      }
    }
    return parts
  }
  
}
