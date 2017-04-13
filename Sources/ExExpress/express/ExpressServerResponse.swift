//
//  ServerResponse.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public extension ServerResponse {
  // TODO: Would be cool: send(stream: GReadableStream), then stream.pipe(self)

  
  /// A reference to the active application. Updated when subapps are triggered.
  public var app : Express? { return extra[ExpressExtKey.app] as? Express }

  
  /// A reference to the request associated with this response.
  public var request : IncomingMessage? {
    return extra[ExpressExtKey.req] as? IncomingMessage
  }
  
  /**
   * The locals dictionary of the response. Use this to store response-scoped
   * data. Be careful with key naming, so that you don't override the data
   * of other middleware.
   *
   * Difference between `extra` and `locals`. Conceptually they are the same,
   * but provide different namespaces. `extra` is used for framework internal
   * stuff (and hence requires unique key, we recommend reverse DNS),
   * while `locals` is open to the application and it is reasonable to use
   * 'plain' keys (like "pageTitle", "results" etc).
   */
  public var locals : [ String : Any ] {
    set {
      extra[ExpressExtKey.locals] = newValue
    }
    get {
      return extra[ExpressExtKey.locals] as? [ String : Any ] ?? [:]
    }
  }
  
  
  // MARK: - Status Handling
  
  /// Set the HTTP status, returns self
  ///
  /// Example:
  ///
  ///     res.status(404).send("didn't find it")
  ///
  @discardableResult
  public func status(_ code: Int) -> Self {
    statusCode = code
    return self
  }
  
  /// Set the HTTP status code and send the status description as the body.
  ///
  public func sendStatus(_ code: Int) throws {
    statusCode = code
    
    // TODO:
    // send(status.statusText)
    try send("HTTP status \(code)")
  }
  
  
  // MARK: - Sending Content
 
  /**
   * Send given String as the response content to the client. If no
   * content-type has been set, the String is checked whether it
   * starts with <html. If so text/html is set as the content-type,
   * text/plain otherwise.
   */
  public func send(_ string: String) throws {
    if canAssignContentType {
      // TODO: be more generic, maybe mod_magic?
      var ctype = string.hasPrefix("<html") ? "text/html" : "text/plain"
      ctype += "; charset=utf-8"
      setHeader("Content-Type", ctype)
    }
    
    try self.end(string)
  }
  
  /// Send the given Byte array to the client. Set type to
  /// "application/octet-stream" if no other type has been set.
  public func send(_ data: [ UInt8 ]) throws {
    if canAssignContentType { // TBD: always true in Apache?
      setHeader("Content-Type", "application/octet-stream")
    }
    
    try self.end(data)
  }
  
  public func send(_ object: JSON)          throws { try json(object) }
  public func send(_ object: JSONEncodable) throws { try json(object) }
  
  /// Returns true if the content type has not been set yet and the headers have
  /// not been send yet.
  var canAssignContentType : Bool {
    return !headersSent && getHeader("Content-Type") == nil
  }
  
  public func format(handlers: [ String : () -> () ]) {
    var defaultHandler : (() -> ())? = nil
    
    guard let rq = request else {
      handlers["default"]?()
      return
    }
    
    for ( key, handler ) in handlers {
      guard key != "default" else { defaultHandler = handler; continue }
      
      if let mimeType = rq.accepts(key) {
        if canAssignContentType {
          setHeader("Content-Type", mimeType)
        }
        handler()
        return
      }
    }
    if let cb = defaultHandler { cb() }
  }
  
  
  // MARK: - Header Accessor Renames
  
  /**
   * Alias for getHeader, returns the value of an HTTP header.
   */
  public func get(_ header: String) -> Any? {
    return getHeader(header)
  }
  /**
   * Alias for setHeader/removeHeader, sets or removes the value of an HTTP
   * header.
   */
  public func set(_ header: String, _ value: Any?) {
    if let v = value {
      setHeader(header, v)
    }
    else {
      removeHeader(header)
    }
  }
}
