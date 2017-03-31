//
//  Route.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

private let patternMarker : UInt8 = 58 // ':'

/**
 * A Route is a middleware which wraps another middleware and guards it by a
 * condition. For example:
 *
 *     app.get("/index") { req, res, next in ... }
 *
 * This creates a Route wrapping the closure given. It only runs the
 * embedded closure if:
 * - the method of the request is 'GET'
 * - the request path is equal to "/index"
 * In all other cases it immediately calls the `next` handler.
 *
 * ## Path Patterns
 *
 * The Route accepts a pattern for the path:
 * - the "*" string is considered a match-all.
 * - otherwise the string is split into path components (on '/')
 * - if it starts with a "/", the pattern will start with a Root symbol
 * - "*" (like in `/users/ * / view`) matches any component (spaces added)
 * - if the component starts with `:`, it is considered a variable.
 *   Example: `/users/:id/view`
 * - "text*", "*text*", "*text" creates hasPrefix/hasSuffix/contains patterns
 * - otherwise the text is matched AS IS
 *
 * Variables can be extracted using:
 *
 *     req.params[int: "id"]
 *
 * and companions.
 */
open class Route: MiddlewareObject, RouteKeeper, CustomStringConvertible {
  
  let debug      = false
  
  var middleware : [ Middleware ]
  
  let methods    : [ String ]?
  
  let urlPattern : [ RoutePattern ]?
    // FIXME: all this works a little different in Express.js. Exact matches,
    //        non-path-component matches, regex support etc.
  
  public init(pattern: String?, method: String?, middleware: [Middleware]) {
    // FIXME: urlPrefix should be url or sth
    
    if let m = method { self.methods = [ m ] }
    else { self.methods = nil }
    
    self.middleware = middleware
    
    self.urlPattern = pattern != nil ? RoutePattern.parse(pattern!) : nil

    if debug { console.log("\(#function): setup route: \(self)") }
  }
  
  
  // MARK: MiddlewareObject
  
  public func handle(request  req: IncomingMessage,
                     response res: ServerResponse,
                     next     cb:  @escaping Next) throws
  {
    let debug = self.debug
    
    guard matches(request: req)    else {
      if debug {
        console.log("\(#function): route does not match, next: \(self)")
      }
      return try cb()
    }
    guard !self.middleware.isEmpty else {
      if debug {
        console.log("\(#function): route has no middleware, next: \(self)")
      }
      return try cb()
    }
    
    if debug { console.log("\(#function): route matches: \(self)") }
    
    // push route state
    let oldParams = req.params
    let oldRoute  = req.route
    req.params = extractPatternVariables(request: req)
    req.route  = self
    let endNext : Next = { _ in
      req.params = oldParams
      req.route  = oldRoute
      if debug { console.log("\(#function): end-next: \(self)") }
      return try cb()
    }
    
    // loop over route middleware
    let stack = self.middleware
    let count = stack.count // optimization ;->
    var next  : Next? = { _ in } // cannot be let as it's self-referencing
    
    var i = 0 // capture position in matching-middleware array (shared)
    
    next = { args in
      
      // grab next item from middleware array
      let middleware = stack[i]
      i += 1 // this is shared between the blocks, move position in array

      if debug {
        if count == 1 {
          console.log("\(#function): handle mw in: \(self)")
        }
        else {
          console.log("\(#function): handle mw \(i)-of-\(count) in: \(self)")
        }
      }
      
      // call the middleware - which gets the handle to go to the 'next'
      // middleware. the latter can be the 'endNext'
      let isLast = i == count
      try middleware(req, res, isLast ? endNext : next!)
      if isLast {
        if debug { console.log("\(#function): last mw of: \(self)") }
        next = nil
      }
    }
    
    // inititate the traversal
    try next!()
  }
  
  
  // MARK: - Matching
  
  func matches(request req: IncomingMessage) -> Bool {
    
    // match methods
    
    if let methods = self.methods {
      guard methods.contains(req.method) else { return false }
    }
    
    // match URLs
    
    if let pattern = urlPattern {
      // TODO: consider mounting!
      let escapedPathComponents = split(urlPath: req.url)
      
      guard let match = RoutePattern.match(pattern: pattern,
                                           against: escapedPathComponents)
       else {
        return false
       }
      
      if debug { console.log("\(#function) match:", match) }
    }
    
    return true
  }
  
  private func split(urlPath s: String) -> [ String ] {
    var url  = URL()
    url.path = s
    return url.escapedPathComponents!
  }
  
  func extractPatternVariables(request rq: IncomingMessage)
       -> [ String : String ]
  {
    guard let pat = urlPattern else { return [:] }
    
    // TODO: consider mounting!
    let matchPrefix = rq.url
    
    var url = URL()
    url.path = matchPrefix
    let matchComponents = url.escapedPathComponents!
    
    var vars = [ String : String ]()
    
    for i in pat.indices {
      guard i < matchComponents.count else { break }
      
      let patternComponent = pat[i]
      let matchComponent   = matchComponents[i]
      
      switch patternComponent {
        case .Variable(let s): vars[s] = matchComponent
        default:               continue
      }
    }
    
    return vars
  }
  
  
  // MARK: - RouteKeeper
  
  public func add(route e: Route) {
    middleware.append(e.middleware)
  }
  
  
  // MARK: - Description
  
  public var description : String {
    var ms = "<Route:"
    
    var hadLimit = false
    if let methods = methods, !methods.isEmpty {
      ms += " "
      ms += methods.joined(separator: ",")
      hadLimit = true
    }
    if let pattern = urlPattern {
      ms += " "
      ms += pattern.map({$0.description}).joined(separator: "/")
      hadLimit = true
    }
    if !hadLimit { ms += " *" }
    
    if middleware.isEmpty {
      ms += " NO-middleware"
    }
    else if middleware.count > 1 {
      ms += " #middleware=\(middleware.count)"
    }
    else {
      ms += " mw"
    }
    
    ms += ">"
    return ms
  }
  
}


// MARK: - Request Extension

private let routeKey = "io.noze.express.route"

public extension IncomingMessage {
  
  public var route : Route? {
    set { extra[routeKey] = newValue }
    get { return extra[routeKey] as? Route }
  }
  
}
