//
//  BodyParser.swift
//  Noze.io
//
//  Created by Helge Hess on 30/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public typealias BodyParserJSON = JSON

/// An enum which stores the result of the `bodyParser` middleware. The result
/// can be accessed as `request.body`, e.g.
///
///     if case .JSON(let json) = request.body {
///       // do JSON stuff
///     }
///
public enum BodyParserBody {
  
  case NotParsed
  case NoBody // IsPerfect
  case Error(Swift.Error)
  
  case URLEncoded(Dictionary<String, Any>)
  
  case JSON(BodyParserJSON)
  
  case Raw([UInt8])
  case Text(String)
  
  public var json : BodyParserJSON? {
    switch self {
      case .JSON(let json): return json
      default: return nil
    }
  }
  
  public var text : String? {
    switch self {
      case .Text(let s): return s
      default: return nil
    }
  }
}

public extension BodyParserBody {
  
  public subscript(key : String) -> Any? {
    get {
      switch self {
        case .URLEncoded(let dict): return dict[key]
        // TODO: support JSON
        default: return nil
      }
    }
  }
  
  public subscript(string key : String) -> String { // TBD: Optional?
    get {
      switch self {
        case .URLEncoded(let dict):
          guard let v = dict[key] else { return "" }
          if let s = v as? String                  { return s }
          if let s = v as? CustomStringConvertible { return s.description }
          return "\(v)"
        
        case .JSON(let json):
          // TBD: index support for arrays?
          guard case let .dictionary(dict) = json, let jsonValue = dict[key]
           else { return "" }
          
          switch jsonValue {
            case .null:          return "<nil>" // TBD
            case .string(let v): return v
            case .double(let v): return String(v)
            case .int   (let v): return String(v)
            case .bool  (let v): return v ? "true" : "false"
            default: return "\(jsonValue)" // TBD
          }
        
        default: return ""
      }
    }
  }
  
  public subscript(int key : String) -> Int? {
    get {
      switch self {
        case .URLEncoded(let dict):
          guard let v = dict[key] else { return nil }
          if let s = v as? Int { return s }
          return Int("\(v)")
        
        case .JSON(let json):
          // TBD: index support for arrays?
          guard case let .dictionary(dict) = json, let jsonValue = dict[key]
           else { return nil }
          
          switch jsonValue {
            case .null:          return nil
            case .string(let v): return Int(v)
            case .double(let v): return Int(v)
            case .int   (let v): return v
            case .bool  (let v): return v ? 1 : 0
            default: return nil
          }
        default: return nil
      }
    }
  }
}

extension BodyParserBody : ExpressibleByStringLiteral {

  public init(stringLiteral value: String) {
    self = .Text(value)
  }
  
  public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
    self = .Text(value)
  }
  
  public init(unicodeScalarLiteral value: StringLiteralType) {
    self = .Text(value)
  }
}


// Module holding the different variants of bodyParsers.
public enum bodyParser {
  
  public class Options {
    let inflate  = false
    let limit    = 100 * 1024
    let extended = true
  }
  
  fileprivate static let requestKey = "io.noze.connect.body-parser.body"
}


public enum BodyParserError : Error {
  
  case ExtraStoreInconsistency
  
}


// MARK: - IncomingMessage extension

public extension IncomingMessage {
  
  public var body : BodyParserBody {
    set {
      extra[bodyParser.requestKey] = newValue
    }
    
    get {
      guard let body = extra[bodyParser.requestKey] else {
        return BodyParserBody.NotParsed
      }
      
      if let body = body as? BodyParserBody { return body }
      
      return BodyParserBody.Error(BodyParserError.ExtraStoreInconsistency)
    }
  }
  
}


// MARK: - JSON

// curl -H "Content-type: application/json" -X POST \
//   -d '{ "login": "xyz", "password": "opq", "port": 80 }' \
//   http://localhost:1337/login

public extension bodyParser {
  
  /// This middleware parses the request body if the content-type is JSON,
  /// and pushes the the JSON parse result into the `body` property of the
  /// request.
  ///
  /// Example:
  ///
  ///     app.use(bodyParser.json())
  ///     app.use { req, res, next in
  ///       print("Log JSON Body: \(req.body.json)")
  ///       next()
  ///     }
  ///
  public static func json(options opts: Options = Options()) -> Middleware {
    return { req, res, next in
      guard typeIs(req, [ "json" ]) != nil else { return next() }
      guard case .NotParsed = req.body else { return next() }
      
      // lame, should be streaming
      let bytes = try req.readBody()

      let result = BodyParserJSON.parse(bytes)
      // TODO: error?
      req.body = result != nil ? .JSON(result!) : .NoBody
      next()
    }
  }

}


// MARK: - Raw & Text

public extension bodyParser {

  public static func raw(options opts: Options = Options()) -> Middleware {
    return { req, res, next in
      guard case .NotParsed = req.body else { return next() }
      
      // lame, should be streaming
      let bytes = try req.readBody()
      req.body = .Raw(bytes)
      next()
    }
  }
  
  public static func text(options opts: Options = Options()) -> Middleware {
    return { req, res, next in
      // text/plain, text/html etc
      // TODO: properly process charset parameter, this assumes UTF-8
      guard typeIs(req, [ "text" ]) != nil else { return next() }
      guard case .NotParsed = req.body else { return next() }
      
      // lame, should be streaming
      let bytes = try req.readBody()
      if let s = String.decode(utf8: bytes) {
        req.body = .Text(s)
      }
      next()
    }
  }
  
}

extension String {
  
  static func decode<I: Collection>(utf8 ba: I) -> String?
                     where I.Iterator.Element == UInt8
  {
    return decode(units: ba, decoder: UTF8())
  }
  
  static func decode<Codec: UnicodeCodec, I: Collection>
                (units b: I, decoder d: Codec) -> String?
                     where I.Iterator.Element == Codec.CodeUnit
  {
    guard !b.isEmpty else { return "" }
    
    let minimumCapacity = 42 // what is a good tradeoff?
    var s = ""
    s.reserveCapacity(minimumCapacity)
    
    var decoder  = d
    var iterator = b.makeIterator()
    while true {
      switch decoder.decode(&iterator) {
        case .scalarValue(let scalar): s.append(String(scalar))
        case .emptyInput: return s
        case .error:      return nil
      }
    }
  }
  
}


// MARK: - URL Encoded

public extension bodyParser {
  
  public static func urlencoded(options opts: Options = Options())
                     -> Middleware
  {
    return { req, res, next in
      guard typeIs(req, [ "application/x-www-form-urlencoded" ]) != nil else {
        return next()
      }
      guard case .NotParsed = req.body else { return next() }
      
      let bytes = try req.readBody()
      guard let s = String.decode(utf8: bytes) else {
        console.error("could not decode body as UTF8")
        return next()
      }
      
      let qp = opts.extended ? qs.parse(s) : querystring.parse(s)
      req.body = .URLEncoded(qp)
      next()
    }
  }
}
