//
//  Route.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

private let patternMarker : UInt8 = 58 // ':'
private let debugMatcher  = false

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
public struct Route: MiddlewareObject {
  
  public enum Pattern {
    case Root
    case Text    (String)
    case Variable(String)
    case Wildcard
    case Prefix  (String)
    case Suffix  (String)
    case Contains(String)
    
    func match(string s: String) -> Bool {
      switch self {
        case .Root:            return s == ""
        case .Text(let v):     return s == v
        case .Wildcard:        return true
        case .Variable:        return true // allow anything, like .Wildcard
        case .Prefix(let v):   return s.hasPrefix(v)
        case .Suffix(let v):   return s.hasSuffix(v)
        case .Contains(let v): return s.contains(v)
      }
    }
  }
  
  let middleware : [ Middleware ]
    // TBD: I think in Express.js, even the Route objects are middleware stack,
    //      and they allow you to hook up multiple objects to the same route
  
  let methods    : [ String ]?
  
  let urlPattern : [ Pattern ]?
    // FIXME: all this works a little different in Express.js. Exact matches,
    //        non-path-component matches, regex support etc.
  
  public init(pattern: String?, method: String?, middleware: [Middleware]) {
    // FIXME: urlPrefix should be url or sth
    
    if let m = method { self.methods = [ m ] }
    else { self.methods = nil }
    
    self.middleware = middleware
    
    self.urlPattern = pattern != nil ? parseURLPattern(url: pattern!) : nil
  }
  
  
  // MARK: MiddlewareObject
  
  public func handle(request  req: IncomingMessage,
                     response res: ServerResponse,
                     next     cb:  @escaping Next) throws
  {
    guard matches(request: req)    else { return try cb() }
    guard !self.middleware.isEmpty else { return try cb() }
    
    // push route state
    let oldParams = req.params
    let oldRoute  = req.route
    req.params = extractPatternVariables(request: req)
    req.route  = self
    let endNext : Next = { _ in
      req.params = oldParams
      req.route  = oldRoute
      return try cb()
    }
    
    // loop over route middleware
    let stack = self.middleware
    var next  : Next? = { _ in } // cannot be let as it's self-referencing
    
    var i = 0 // capture position in matching-middleware array (shared)
    
    next = { args in
      
      // grab next item from middleware array
      let middleware = stack[i]
      i += 1 // this is shared between the blocks, move position in array
      
      // call the middleware - which gets the handle to go to the 'next'
      // middleware. the latter can be the 'endNext'
      let isLast = i == stack.count
      try middleware(req, res, isLast ? endNext : next!)
      if isLast { next = nil }
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
    
    if var pattern = urlPattern {
      // TODO: consider mounting!
      
      let escapedPathComponents = split(urlPath: req.url)
      if debugMatcher {
        print("MATCH: \(req.url)\n  components: \(escapedPathComponents)\n" +
              "  against: \(pattern)")
      }
      
      // this is to support matching "/" against the "/*" ("", "*") pattern
      if escapedPathComponents.count + 1 == pattern.count {
        if case .Wildcard = pattern.last! {
          let endIdx = pattern.count - 1
          pattern = Array<Pattern>(pattern[0..<endIdx])
        }
      }
      
      guard escapedPathComponents.count >= pattern.count else { return false }
      
      var lastWasWildcard = false
      for i in pattern.indices {
        let patternComponent = pattern[i]
        let matchComponent   = escapedPathComponents[i]
        
        guard patternComponent.match(string: matchComponent) else {
          return false
        }
        
        if debugMatcher {
          print("  MATCHED[\(i)]: \(patternComponent) \(matchComponent)")
        }
        
        // Special case, last component is a wildcard. Like /* or /todos/*. In
        // this case we ignore extra URL path stuff.
        if case .Wildcard = patternComponent {
          let isLast = i + 1 == pattern.count
          if isLast { lastWasWildcard = true }
        }
      }
      
      if escapedPathComponents.count > pattern.count {
        if !lastWasWildcard { return false }
      }
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
  
}

/**
 * Creates a pattern for a given 'url' string.
 *
 * - the "*" string is considered a match-all.
 * - otherwise the string is split into path components (on '/')
 * - if it starts with a "/", the pattern will start with a Root symbol
 * - "*" (like in `/users/ * / view`) matches any component (spaces added)
 * - if the component starts with `:`, it is considered a variable.
 *   Example: `/users/:id/view`
 * - "text*", "*text*", "*text" creates hasPrefix/hasSuffix/contains patterns
 * - otherwise the text is matched AS IS
 */
func parseURLPattern(url s: String) -> [ Route.Pattern ]? {
  if s == "*" { return nil } // match-all
  
  var url = URL()
  url.path = s
  let comps = url.escapedPathComponents!
  
  var isFirst = false
  
  var pattern : [ Route.Pattern ] = []
  for c in comps {
    if isFirst {
      isFirst = false
      if c == "" { // root
        pattern.append(.Root)
        continue
      }
    }
    
    if c == "*" {
      pattern.append(.Wildcard)
      continue
    }
    
    if c.hasPrefix(":") {
      let vIdx = c.index(after: c.startIndex)
      pattern.append(.Variable(c[vIdx..<c.endIndex]))
      continue
    }
    
    if c.hasPrefix("*") {
      let vIdx = c.index(after: c.startIndex)
      if c == "**" {
        pattern.append(.Wildcard)
      }
      else if c.hasSuffix("*") && c.characters.count > 1 {
        let eIdx = c.index(before: c.endIndex)
        pattern.append(.Contains(c[vIdx..<eIdx]))
      }
      else {
        pattern.append(.Prefix(c[vIdx..<c.endIndex]))
      }
      continue
    }
    if c.hasSuffix("*") {
      let eIdx = c.index(before: c.endIndex)
      pattern.append(.Suffix(c[c.startIndex..<eIdx]))
      continue
    }

    pattern.append(.Text(c))
  }
  
  return pattern
}

private let routeKey = "io.noze.express.route"

public extension IncomingMessage {
  
  public var route : Route? {
    set { extra[routeKey] = newValue }
    get { return extra[routeKey] as? Route }
  }
  
}
