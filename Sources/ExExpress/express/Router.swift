//
//  Router.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

/**
 * A Middleware which keeps and runs an array of Route objects.
 *
 * Note: The is also the RouteKeeper protocol which has all the nice `use()`,
 *       `get` etc methods.
 *
 * Note: You don't have to create a Router object manually, the Express app
 *       object has a main router object you can use (and implements
 *       RouteKeeper enabling all the `get`, `use`, etc hook-methods).
 */
open class Router: MiddlewareObject, RouteKeeper {
  // TBD: could be a struct?
  
  var routes = [ Route ]()
  
  public func add(route e: Route) {
    routes.append(e)
  }
  
  
  // MARK: MiddlewareObject
  
  public func handle(request  req     : IncomingMessage,
                     response res     : ServerResponse,
                     next     endNext : @escaping Next) throws
  {
    guard !self.routes.isEmpty else { return try endNext() }
    
    let routes = self.routes // make a copy to protect against modifications
    var next : Next? = { _ in } // cannot be let as it's self-referencing
    
    var i = 0 // capture position in matching-middleware array (shared)
    
    next = { args in
      
      // grab next item from matching middleware array
      let route      = routes[i]
      i += 1 // this is shared between the blocks, move position in array
      
      // call the middleware - which gets the handle to go to the 'next'
      // middleware. the latter can be the 'endNext'
      let isLast = i == routes.count
      try route.handle(request: req, response: res,
                       next: isLast ? endNext : next!)
      if isLast { next = nil }
    }
    
    // inititate the traversal
    try next!()
  }
  
}
