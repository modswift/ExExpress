//
//  TypeIs.swift
//  Noze.io
//
//  Created by Helge Hess on 30/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//


// TODO: the API is both crap nor really the same like Node

/**
 * Checks whether the content-type of the `IncomingMessage` matches one of the
 * types passed in.
 *
 * Example:
 *
 *     public static func json(options opts: Options = Options()) -> Middleware {
 *       return { req, res, next in
 *         guard typeIs(req, [ "json" ]) != nil else { return next() }
 *         guard case .NotParsed = req.body     else { return next() }
 *     ...
 *
 * Note: Express also adds `IncomingMessage.is()`, which may be more appropriate
 *       for user-level code.
 */
public func typeIs(_ message: IncomingMessage, _ types: [ String ])
            -> String?
{
  // Note: We still keep this because the BodyParser module uses it, and doesn't
  //       have a dependency on Express.
  let ctypeO = message.getHeader("Content-Type") as? String
  guard let ctype = ctypeO else { return nil }
  return typeIs(ctype, types)
}

public func typeIs(_ type: String, _ types: [ String ]) -> String? {
  let lcType = type.lowercased()
  
  for matchType in types {
    if does(type: lcType, match: matchType) {
      return matchType
    }
  }
  
  return nil
}

private func does(type lcType: String, match matchType: String) -> Bool {
  let lcMatch = matchType.lowercased()
  
  if lcType == lcMatch { return true }
  
  // FIXME: completely naive implementation :->
  
  if lcMatch.hasSuffix("*") {
    let idx = lcMatch.index(before: lcMatch.endIndex)
    let lcPatMatch = lcMatch.substring(to: idx)
    return lcType.hasPrefix(lcPatMatch)
  }
  
  if lcType.contains(lcMatch) {
    return true
  }
  
  return false
}
