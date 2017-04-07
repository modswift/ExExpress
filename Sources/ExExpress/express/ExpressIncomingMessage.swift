//
//  IncomingMessage.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public extension IncomingMessage {
  
  // TODO: baseUrl, originalUrl, path
  // TODO: hostname, ip, ips, protocol
  
  public func accepts(_ s: String) -> String? {
    // TODO: allow array values
    guard let acceptHeader = (self.getHeader("accept") as? String) else {
      return nil
    }
    
    // FIXME: naive and incorrect implementation :-)
    // TODO: parse quality, patterns, etc etc
    let ls = s.lowercased()
    let acceptedTypes = acceptHeader.characters.split(separator: ",")
    for mimeType in acceptedTypes {
      let mimeTypeString = String(mimeType)
      if mimeTypeString.lowercased().contains(ls) { return mimeTypeString }
    }
    return nil
  }
  
  /**
   * Check whether the Content-Type of the request matches the given `pattern`.
   *
   * The current implementation just checks whether the request content-type
   * contains the given pattern as a substring
   * (FIXME: should support stuff like `image/ star `)
   *
   * Example:
   *
   *     app.use { req, res, next in
   *       guard req.is("text/json") else { return next() }
   *       // deal with JSON
   *     }
   */
  public func `is`(_ pattern: String) -> Bool {
    // TODO: support text/* and such
    guard let ctype = (self.getHeader("content-type") as? String) else {
      return false
    }
    
    // FIXME: naive and incorrect implementation :-)
    // TODO: parse quality, patterns, etc etc
    return ctype.lowercased().contains(pattern.lowercased())
  }
  
  /**
   * This is true if the request was triggered by an `XMLHtttpRequest`
   * (checks the `X-Requested-With` header).
   */
  public var xhr : Bool {
    guard let h = (getHeader("X-Requested-With") as? String) else {
      return false
    }
    return h.contains("XMLHttpRequest")
  }
}
