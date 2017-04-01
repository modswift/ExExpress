//
//  RouteKeeper.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

/**
 * An object which keeps routes.
 *
 * Within the express module only the Express object itself is a route keeper.
 *
 * The primary purpose of this protocol is to decouple all the convenience 
 * `use`, `get` etc functions from the actual functionality: `add(route:)`.
 */
public protocol RouteKeeper: class {
  
  func add(route e: Route)
  
}

// MARK: - Route Method

public extension RouteKeeper {
  
  /**
   * Returns a route to gate on a path. Since a `Route` itself is a RouteKeeper,
   * you can then hookup additional routes.
   *
   * Example:
   *
   *     app.route("/cows")
   *       .get  { req, res, next ... }
   *       .post { req, res, next ... }
   *
   * Note: A Route is not a mountable object! I.e. this doesn't do the thing
   * you expect:
   *
   *     app.route("/admin"
   *       .get("/view") { .. }   // does NOT match /admin/view, but /view
   *
   * Use a new `Express` instance for mounting.
   */
  public func route(_ p: String) -> Route {
    let route = Route(pattern: p)
    add(route: route)
    return route
  }
  
}


// MARK: - Add Middleware
  
// TBD: all the duplication below looks a little stupid, is there a better way
//      w/o resorting to Any? Also we can only take uniform lists of middleware
//      (e.g. not mix & match regular and error mw)

public extension RouteKeeper {
  
  @discardableResult
  public func use(_ cb: Middleware...) -> Self {
    add(route: Route(pattern: nil, method: nil, middleware: cb))
    return self
  }
  
  @discardableResult
  public func use(_ p: String, _ cb: Middleware...) -> Self {
    add(route: Route(pattern: p, method: nil, middleware: cb))
    return self
  }
  
  @discardableResult
  public func all(_ p: String, _ cb: Middleware...) -> Self {
    add(route: Route(pattern: p, method: nil, middleware: cb))
    return self
  }
  
  @discardableResult
  public func get(_ p: String, _ cb: Middleware...) -> Self {
    add(route: Route(pattern: p, method: "GET", middleware: cb))
    return self
  }
  @discardableResult
  public func post(_ p: String, _ cb: Middleware...) -> Self {
    add(route: Route(pattern: p, method: "POST", middleware: cb))
    return self
  }
  @discardableResult
  public func head(_ p: String, _ cb: Middleware...) -> Self {
    add(route: Route(pattern: p, method: "HEAD", middleware: cb))
    return self
  }
  @discardableResult
  public func put(_ p: String, _ cb: Middleware...) -> Self {
    add(route: Route(pattern: p, method: "PUT", middleware: cb))
    return self
  }
  @discardableResult
  public func del(_ p: String, _ cb: Middleware...) -> Self {
    add(route: Route(pattern: p, method: "DELETE", middleware: cb))
    return self
  }
  @discardableResult
  public func patch(_ p: String, _ cb: Middleware...) -> Self {
    add(route: Route(pattern: p, method: "PATCH", middleware: cb))
    return self
  }

  @discardableResult
  public func get(_ cb: Middleware...) -> Self {
    add(route: Route(pattern: nil, method: "GET", middleware: cb))
    return self
  }
  @discardableResult
  public func post(_ cb: Middleware...) -> Self {
    add(route: Route(pattern: nil, method: "POST", middleware: cb))
    return self
  }
  @discardableResult
  public func head(_ cb: Middleware...) -> Self {
    add(route: Route(pattern: nil, method: "HEAD", middleware: cb))
    return self
  }
  @discardableResult
  public func put(_ cb: Middleware...) -> Self {
    add(route: Route(pattern: nil, method: "PUT", middleware: cb))
    return self
  }
  @discardableResult
  public func del(_ cb: Middleware...) -> Self {
    add(route: Route(pattern: nil, method: "DELETE", middleware: cb))
    return self
  }
  @discardableResult
  public func patch(_ cb: Middleware...) -> Self {
    add(route: Route(pattern: nil, method: "PATCH", middleware: cb))
    return self
  }
}

public extension RouteKeeper {
    
  @discardableResult
  public func use(_ cb: ErrorMiddleware...) -> Self {
    add(route: Route(pattern: nil, method: nil, middleware: cb))
    return self
  }
  
  @discardableResult
  public func use(_ p: String, _ cb: ErrorMiddleware...) -> Self {
    add(route: Route(pattern: p, method: nil, middleware: cb))
    return self
  }
  
  @discardableResult
  public func all(_ p: String, _ cb: ErrorMiddleware...) -> Self {
    add(route: Route(pattern: p, method: nil, middleware: cb))
    return self
  }
  
  @discardableResult
  public func get(_ p: String, _ cb: ErrorMiddleware...) -> Self {
    add(route: Route(pattern: p, method: "GET", middleware: cb))
    return self
  }
  @discardableResult
  public func post(_ p: String, _ cb: ErrorMiddleware...) -> Self {
    add(route: Route(pattern: p, method: "POST", middleware: cb))
    return self
  }
  @discardableResult
  public func head(_ p: String, _ cb: ErrorMiddleware...) -> Self {
    add(route: Route(pattern: p, method: "HEAD", middleware: cb))
    return self
  }
  @discardableResult
  public func put(_ p: String, _ cb: ErrorMiddleware...) -> Self {
    add(route: Route(pattern: p, method: "PUT", middleware: cb))
    return self
  }
  @discardableResult
  public func del(_ p: String, _ cb: ErrorMiddleware...) -> Self {
    add(route: Route(pattern: p, method: "DELETE", middleware: cb))
    return self
  }
  @discardableResult
  public func patch(_ p: String, _ cb: ErrorMiddleware...) -> Self {
    add(route: Route(pattern: p, method: "PATCH", middleware: cb))
    return self
  }

  @discardableResult
  public func get(_ cb: ErrorMiddleware...) -> Self {
    add(route: Route(pattern: nil, method: "GET", middleware: cb))
    return self
  }
  @discardableResult
  public func post(_ cb: ErrorMiddleware...) -> Self {
    add(route: Route(pattern: nil, method: "POST", middleware: cb))
    return self
  }
  @discardableResult
  public func head(_ cb: ErrorMiddleware...) -> Self {
    add(route: Route(pattern: nil, method: "HEAD", middleware: cb))
    return self
  }
  @discardableResult
  public func put(_ cb: ErrorMiddleware...) -> Self {
    add(route: Route(pattern: nil, method: "PUT", middleware: cb))
    return self
  }
  @discardableResult
  public func del(_ cb: ErrorMiddleware...) -> Self {
    add(route: Route(pattern: nil, method: "DELETE", middleware: cb))
    return self
  }
  @discardableResult
  public func patch(_ cb: ErrorMiddleware...) -> Self {
    add(route: Route(pattern: nil, method: "PATCH", middleware: cb))
    return self
  }
}

fileprivate func mountIfPossible(pattern  : String,
                                 parent   : RouteKeeper,
                                 children : [ MiddlewareObject ])
{
  guard let parent = parent as? Express else { return }

  for child in children {
    guard let child = child as? MountableMiddlewareObject else { continue }
    child.mount(at: pattern, parent: parent)
  }
}

public extension RouteKeeper {
  // Directly attach MiddlewareObject's as Middleware. That is:
  //   let app   = express()
  //   let admin = express()
  //   app.use("/admin", admin)
  // TBD: should we have a Route which keeps the object? Has various advantages,
  //      particularily during debugging.
  
  @discardableResult
  public func use(_ mw: MiddlewareObject...) -> Self {
    add(route: Route(pattern: nil, method: nil, middleware: mw))
    return self
  }
  
  @discardableResult
  public func use(_ p: String, _ mw: MiddlewareObject...) -> Self {
    mountIfPossible(pattern: p, parent: self, children: mw)
    add(route: Route(pattern: p, method: nil, middleware: mw))
    return self
  }
  
  @discardableResult
  public func all(_ p: String, _ mw: MiddlewareObject...) -> Self {
    mountIfPossible(pattern: p, parent: self, children: mw)
    add(route: Route(pattern: p, method: nil, middleware: mw))
    return self
  }
  
  @discardableResult
  public func get(_ p: String, _ mw: MiddlewareObject...) -> Self {
    mountIfPossible(pattern: p, parent: self, children: mw)
    add(route: Route(pattern: p, method: "GET", middleware: mw))
    return self
  }
  
  @discardableResult
  public func post(_ p: String, _ mw: MiddlewareObject...) -> Self {
    mountIfPossible(pattern: p, parent: self, children: mw)
    add(route: Route(pattern: p, method: "POST", middleware: mw))
    return self
  }
  
  @discardableResult
  public func head(_ p: String, _ mw: MiddlewareObject...) -> Self {
    mountIfPossible(pattern: p, parent: self, children: mw)
    add(route: Route(pattern: p, method: "HEAD", middleware: mw))
    return self
  }
  
  @discardableResult
  public func put(_ p: String, _ mw: MiddlewareObject...) -> Self {
    mountIfPossible(pattern: p, parent: self, children: mw)
    add(route: Route(pattern: p, method: "PUT", middleware: mw))
    return self
  }
  
  @discardableResult
  public func del(_ p: String, _ mw: MiddlewareObject...) -> Self {
    mountIfPossible(pattern: p, parent: self, children: mw)
    add(route: Route(pattern: p, method: "DELETE", middleware: mw))
    return self
  }
  
  @discardableResult
  public func patch(_ p: String, _ mw: MiddlewareObject...) -> Self {
    mountIfPossible(pattern: p, parent: self, children: mw)
    add(route: Route(pattern: p, method: "PATCH", middleware: mw))
    return self
  }
}
