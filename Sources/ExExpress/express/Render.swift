//
//  Render.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public enum ExpressRenderingError: Error {
  case NoApplicationActive
  case UnsupportedViewEngine(String)
}

public extension ServerResponse {
  
  /**
   * Lookup a template with the given name, locate the rendering engine for it,
   * and render it with the options that are passed in.
   *
   * Example:
   *
   *     app.get { _, res, _ in
   *       try res.render('index', { "title": "Hello World!" })
   *     }
   *
   * Assuming your 'views' directory contains an `index.mustache` file, this
   * would trigger the Mustache engine to render the template with the given
   * dictionary as input.
   *
   * When no options are passed in, render will fallback to the `view options`
   * setting in the application (TODO: merge the two contexts).
   */
  public func render(_ template: String, _ options : Any? = nil) throws {
    guard let app = self.app else {
      throw ExpressRenderingError.NoApplicationActive
    }
    
    try app.render(template: template, options: options, to: self)
  }
}

public extension Express {
  
  /**
   * Lookup a template with the given name, locate the rendering engine for it,
   * and render it with the options that are passed in.
   *
   * Refer to the `ServerResponse.render` method for details.
   */
  public func render(template: String, options: Any?, to res: ServerResponse)
                throws
  {
    let viewEngine = (get("view engine") as? String) ?? "mustache"
    guard let engine = engines[viewEngine] else {
      throw ExpressRenderingError.UnsupportedViewEngine(viewEngine)
    }
    
    let viewsPath      = viewDirectory(for: viewEngine, response: res)
    let emptyOpts      : [ String : Any ] = [:]
    let appViewOptions = get("view options") ?? emptyOpts
    let viewOptions    = options ?? appViewOptions
      // TODO: merge if possible (custom KVC wrapper ...)
    
    try lookupTemplate(views: viewsPath, template: template,
                       engine: viewEngine) {
      pathOrNot in
                        
      guard let path = pathOrNot else {
        res.writeHead(404)
        try res.end()
        return
      }
      
      try engine(path, viewOptions) { results in
        let rc = results.count
        let v0 = rc > 0 ? results[0] : nil
        let v1 = rc > 1 ? results[1] : nil
        
        if let error = v0 {
          console.error("template error: \(error)")
          res.writeHead(500)
          try res.end()
          return
        }
        
        guard let result = v1 else {
          console.warn("template returned no content: \(template) \(results)")
          res.writeHead(204)
          try res.end()
          return
        }

        // TBD: maybe support a stream as a result? (result.pipe(res))
        let s = (result as? String) ?? "\(result)"

        // Wow, this is harder than it looks when we want to consider a MIMEType
        // object as a value :-)
        var setContentType = true
        if let oldType = res.getHeader("Content-Type") {
          let s = (oldType as? String) ?? String(describing: oldType) // FIXME
          setContentType = (s == "httpd/unix-directory") // a hack for Apache
        }
        
        if setContentType {
          // FIXME: also consider extension of template (.html, .vcf etc)
          res.setHeader("Content-Type", detectTypeForContent(string: s))
        }
        
        res.writeHead(200)
        try res.write(s)
        try res.end()
      }
    }
  }
  
}

// TODO: move somewhere else
fileprivate let typePrefixMap = [
  ( "<!DOCTYPE html",  "text/html; charset=utf-8" ),
  ( "<html",           "text/html; charset=utf-8" ),
  ( "<?xml",           "text/xml;  charset=utf-8" ),
  ( "BEGIN:VCALENDAR", "text/calendar; charset=utf-8" ),
  ( "BEGIN:VCARD",     "text/vcard; charset=utf-8" )
]

fileprivate
func detectTypeForContent(string: String,
                          default: String = "text/html; charset=utf-8")
     -> String
{
  // TODO: more clever detection? ;-)
  for ( prefix, type ) in typePrefixMap {
    if string.hasPrefix(prefix) { return type }
  }
  return `default`
}

private func lookupTemplate(views p: String, template t: String,
                            engine e: String,
                            _ cb: ( String? ) throws -> Void) throws
{
  // TODO: try other combos
  let fsPath = "\(p)/\(t).\(e)"
  
  var error : Error? = nil
  
  // TODO: hack-adjust for Apache/throws
  fs.stat(fsPath) { err, stat in
    do {
      guard err == nil && stat != nil else {
        console.error("did not find template \(t) at \(fsPath)")
        try cb(nil)
        return
      }
      guard stat!.isFile() else {
        console.error("template path is not a file: \(fsPath)")
        try cb(nil)
        return
      }
      try cb(fsPath)
    }
    catch (let thrownError) {
      error = thrownError
    }
  }
  
  if error != nil { throw error! }
}

// Some protocol is implemented in Foundation, requiring this.
import Foundation
