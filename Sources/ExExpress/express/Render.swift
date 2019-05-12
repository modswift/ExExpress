//
//  Render.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016-2019 ZeeZide GmbH. All rights reserved.
//

public enum ExpressRenderingError: Error {
  case NoApplicationActive
  case UnsupportedViewEngine(String)
  case TemplateError(Any)
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
  func render(_ template: String, _ options : Any? = nil) throws {
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
  func render(template: String, options: Any?, to res: ServerResponse) throws {
    let viewEngine = (get("view engine") as? String) ?? "mustache"
    guard let engine = engines[viewEngine] else {
      throw ExpressRenderingError.UnsupportedViewEngine(viewEngine)
    }
    
    let viewsPath      = viewDirectory(for: viewEngine, response: res)
    let emptyOpts      : [ String : Any ] = [:]
    let appViewOptions = get("view options") ?? emptyOpts
    let viewOptions    = options ?? appViewOptions
      // TODO: merge if possible (custom KVC wrapper ...)
    
    
    // TODO: Add lookup cache? Maybe. Technically a single cache for the
    //       view content would be cool, but the API is not really supporting
    //       this.
    guard let path = lookupTemplatePath(template, in: viewsPath,
                                        preferredEngine: viewEngine)
     else {
      // TBD: rather throw (maybe w/ a HTTPError '404' marker)
      res.writeHead(404)
      try res.end()
      return
     }
    
    try engine(path, viewOptions) { ( results: Any?... ) in
      let rc = results.count
      let v0 = rc > 0 ? results[0] : nil
      let v1 = rc > 1 ? results[1] : nil
      
      if let error = v0 {
        throw ExpressRenderingError.TemplateError(error)
      }
      
      guard let result = v1 else {
        console.warn("template returned no content: \(template) \(results)")
        res.writeHead(204)
        try res.end()
        return
      }

      // TBD: maybe support a stream as a result? (result.pipe(res))
      // Or generators, there are many more options.
      if !(result is String) {
        console.warn("template rendering result is not a String:", result)
      }
      
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
  
  func lookupTemplatePath(_ template: String, in dir: String,
                          preferredEngine: String? = nil) -> String?
  {
    // Hm, Swift only has pathComponents on URL?
    // FIXME
    
    if let ext = preferredEngine {
      let fsPath = dir + "/" + template + "." + ext
      
      if let stat = try? fs.statSync(fsPath) {
        if stat.isFile() { return fsPath }
      }
    }
    
    for ext in engines.keys {
      let fsPath = dir + "/" + template + "." + ext
      if let stat = try? fs.statSync(fsPath) {
        if stat.isFile() { return fsPath }
      }
    }
    
    return nil
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

// Some protocol is implemented in Foundation, requiring this.
import Foundation
