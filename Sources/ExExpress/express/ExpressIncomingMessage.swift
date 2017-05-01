//
//  IncomingMessage.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public extension IncomingMessage {
  
  // TODO: originalUrl, path
  // TODO: hostname, ip, ips, protocol

  /// A reference to the active application. Updated when subapps are triggered.
  public var app : Express? { return extra[ExpressExtKey.app] as? Express }
  
  /**
   * Contains the request parameters.
   *
   * Example:
   *
   *     app.use(/users/:id/view) { req, res, next in
   *       guard let id = req.params[int: "id"]
   *        else { return try res.sendStatus(400) }
   *     }
   */
  public var params : [ String : String ] {
    set {
      extra[ExpressExtKey.params] = newValue
    }
    get {
      // TODO: should be :Any
      return (extra[ExpressExtKey.params] as? [ String : String ]) ?? [:]
    }
  }
  
  public var query : [ String : Any ] {
    if let q = extra[ExpressExtKey.query] as? [ String : Any ] { return q }
    
    // TODO: shoe[color]=blue gives shoe.color = blue
    // FIXME: cannot use url.parse due to overload
    guard let q = URL(url).query else { return [:] }
    return querystring.parse(q)
  }
  
  /**
   * Contains the part of the URL which matched the current route. Example:
   *
   *     app.get("/admin/index") { ... }
   *
   * when this is invoked with "/admin/index/hello/world", the baseURL will
   * be "/admin/index".
   */
  public var baseURL : String? {
    set { extra[ExpressExtKey.baseURL] = newValue }
    get { return extra[ExpressExtKey.baseURL] as? String }
  }
  
  /// The active route.
  public var route : Route? {
    set { extra[ExpressExtKey.route] = newValue }
    get { return extra[ExpressExtKey.route] as? Route }
  }
  
  
  /**
   * Checks whether the Accept header of the client indicates that the client
   * can deal with the given type, and returns the Accept pattern which matched
   * the type.
   *
   * Example:
   *
   *     app.get("/index") { req, res, next in
   *       if req.accepts("json") != nil {
   *         try res.json(todos.getAll())
   *       }
   *       else { try res.send("Hello World!") }
   *     }
   */
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
