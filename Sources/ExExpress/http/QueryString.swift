//
//  QueryString.swift
//  Noze.io
//
//  Created by Helge Heß on 5/17/16.
//  Copyright © 2016-2019 ZeeZide GmbH. All rights reserved.
//

import Foundation // for String.hasPrefix/hasSuffix

public enum querystring {
  // TODO: doesn't really belong here, but well.
  // TODO: stringify etc
  // TODO: this is a little funky because URL parsing really happens at a byte
  //       level (% decoding etc)
  
  public static func parse(_ string      : String,
                           separator     : Character = "&",
                           pairSeparator : Character = "=",
                   decodeURIComponent dd : (( String ) -> String)? = nil)
                     -> Dictionary<String, Any>
  {
    let decodeURIComponent = dd ?? _unescape
    return _parse(string: string,
                  separator: separator, pairSeparator: pairSeparator,
                  decodeURIComponent: decodeURIComponent)
  }
}


// MARK: - Implementation

private func _parse(string s     : String,
                    separator     : Character = "&",
                    pairSeparator : Character = "=",
                    emptyValue    : Any       = "",
                    zopeFormats   : Bool      = true,
                    decodeURIComponent : (( String ) -> String) = _unescape)
     -> Dictionary<String, Any>
{
  guard !s.isEmpty else { return [:] }
  
  var qp = Dictionary<String, Any>()
  
  #if swift(>=3.2)
    let pairs = s.split(separator: separator, omittingEmptySubsequences: true)
  #else
    let pairs = s.characters.split(separator: separator,
                                   omittingEmptySubsequences: true)
  #endif
  for pair in pairs {
    let pairParts = pair.split(separator: pairSeparator,
                               maxSplits: 1,
                               omittingEmptySubsequences: true)
    guard !pairParts.isEmpty else { continue }
    
    // check key and whether it contains Zope style formats
    
    let keyPart  = decodeURIComponent(String(pairParts[0]))
    #if swift(>=4.2)
      let fmtIdx = keyPart.firstIndex(of: ":")
    #elseif swift(>=3.2)
      let fmtIdx = keyPart.index(of: ":")
    #else
      let fmtIdx = keyPart.characters.index(of: ":")
    #endif
    let key     : String
    let formats : String?
    
    if zopeFormats && fmtIdx != nil  {
      key     = String(keyPart[keyPart.startIndex..<fmtIdx!])
      formats =
        String(keyPart[keyPart.index(after: fmtIdx!)..<keyPart.endIndex])
    }
    else {
      key     = String(keyPart)
      formats = nil
    }
    
    // check whether there is a key but no value ...
    
    if pairParts.count == 1 {
      if qp[key] == nil {
        qp[key] = emptyValue
      }
      continue
    }
    
    // get value
    
    let rawValue = decodeURIComponent(String(pairParts[1]))
    let value : Any
    
    if let formats = formats {
      // TODO: record, list, tuple, array:
      //       e.g.: person.age:int:record
      if formats.hasPrefix("list") || formats.hasPrefix("tuple") ||
         formats.hasPrefix("array")
      {
        console.error("list parameter not yet implement: \(formats)")
        value = rawValue
      }
      else if formats.hasPrefix("record") {
        console.error("record parameter not yet implement: \(formats)")
        value = rawValue
      }
      else {
        if let zvalue = parseZQPValue(string: rawValue, format: formats) {
          value = zvalue
        }
        else {
          continue // TBD: skip
        }
      }
    }
    else {
      value = rawValue
    }
    
    if let existingValue = qp[key] {
      var a : Array<Any>
      if let aa = existingValue as? Array<Any> {
        a = aa
      }
      else {
        a = Array<Any>()
        a.append(existingValue)
      }
      a.append(value)
      qp[key] = a
    }
    else {
      qp[key] = value
    }
  }
  
  return qp
}


/// Zope like value formatter
///
/// As explained in 
/// [Passing Parameters to Scripts](http://www.faqs.org/docs/ZopeBook/ScriptingZope.html)
///
/// You can annotate form names with "filters" to convert strings being
/// passed in by browsers into objects, eg:
///
///     <input type="text" name="age:int" />
///
/// When the browser submits the form, "age:int" will initially be stored
/// as a string. This method will detect the ":int" suffix and create an
/// Integer object keyed under 'age'. That is, you will be able to do this:
///
///     let age = qp["age"] as? Int
///
/// The facility is quite powerful, eg filters can be nested.
///
public func parseZQPValue(string s: String, format: String) -> Any? {
  // TODO: date, tokens, required
  switch format {
    case "int", "long": return Int(s)
    case "float":       return Float(s)
    case "string":      return s
    
    case "text":
      #if swift(>=3.2)
        return String(s.filter({$0 != "\r"}))
      #else
        return String(s.characters.filter({$0 != "\r"}))
      #endif
    
    case "lines":
      #if swift(>=3.2)
        let lines = s.filter({$0 != "\r"}).split(separator: "\n")
      #else
        let lines = s.characters.filter({$0 != "\r"}).split(separator: "\n")
      #endif
      return lines.map { String($0) }
    
    case "boolean":
      switch s {
        case "1", "Y", "y", "yes", "YES", "on", "ON": return true
        default: return false
      }
    
    case "ignore_empty":
      return s.isEmpty ? nil : s
    
    case "method", "action", "default_method", "default_action":
      return s
    
    default:
      console.error("Unsupported query value format: \(format)")
      return s
  }
}


import Foundation

/// %-unescape a string.
private func _unescape(string: String) -> String {
  return string.replacingOccurrences(of: "+", with: " ")
               .removingPercentEncoding ?? string
}
