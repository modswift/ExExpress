//
//  Mustache.swift
//  Noze.io
//
//  Created by Helge Hess on 02/06/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import mustache

// TODO: add caching.
//       A little complicated because we do not get access the the application
//       object?! (we can add a global cache, but we don't know whether we
//       _should_ cache.

/**
 * An Express template engine that renders simple Mustache templates.
 *
 * Checkout [mustache.github.io](http://mustache.github.io) for Mustache
 * documentation.
 *
 * Note: partials currently must live in the same directory like the parent.
 */
func mustacheExpress() -> ExpressEngine {
  return { path, options, callback in
    guard let template = fs.readFileSync(path, "utf8") else {
      return try callback(fs.Error.ReadError)
    }
    
    let parser = MustacheParser()
    let tree   = parser.parse(string: template)
    
    let ctx = ExpressMustacheContext(path: path, object: options)
    
    var renderError : Error? = nil
    tree.render(inContext: ctx) { result in
      do {
        try callback(nil, result)
      }
      catch (let error) {
        renderError = error
      }
    }
    
    // TBD: why do we throw this?
    if renderError != nil { throw renderError! }
  }
}

/**
 * This class is used to process Mustache partial templates. I.e. templates
 * included in other Mustache templates like so:
 *
 *     {{> header }}
 *     ... content ...
 *     {{> footer }}
 */
fileprivate class ExpressMustacheContext : MustacheDefaultRenderingContext {
  
  let viewPath : String // Note: can be a subdir!
  let suffix   : String
  
  init(path p: String, object root: Any?, extension e: String = "mustache") {
    self.viewPath = path.dirname(p)
    self.suffix   = "." + e
    super.init(root)
  }
  
  override func retrievePartial(name n: String) -> MustacheNode? {
    // TODO: throwing API
    
    let ns = n.hasSuffix(suffix) ? n : n + suffix
    guard let partialPath = lookupPath(for: ns) else {
      console.error("could not locate partial:", n)
      return nil
    }
    
    guard let template = fs.readFileSync(partialPath, "utf8") else {
      console.error("could not load partial:", n, partialPath)
      return nil
    }
    
    let parser = MustacheParser()
    let tree   = parser.parse(string: template)
    return tree
  }
  
  func lookupPath(for name: String) -> String? {
    // TODO: proper fsname funcs
    // TODO: it would be nice to recurse upwards, but we need a point where to
    //       stop.
    return viewPath + "/" + name
  }
  
}


// Dirutil helper

#if os(Linux)
  import func Glibc.dirname
  import func Glibc.strdup
  import func Glibc.free
#else
  import func Darwin.dirname
#endif

enum path {
  
  static func dirname(_ p: String) -> String {
    guard !p.isEmpty else { return "" }
    return p.withCString { cstr in
      #if os(Linux)
        // Linux reserves the right to modify the path which is passed in ...
        let mp = strdup(cstr)
        defer { free(mp) }
        return String(cString: Glibc.dirname(mp))
      #else
        let mp = UnsafeMutablePointer(mutating: cstr)
        return String(cString: Darwin.dirname(mp))
      #endif
    }
  }
  
}
