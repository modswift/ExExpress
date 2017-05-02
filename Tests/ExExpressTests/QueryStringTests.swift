//
//  QueryStringTests.swift
//  ExExpress
//
//  Created by Helge Hess on 02.05.17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

import XCTest
@testable import ExExpress

class QueryStringTests: XCTestCase {
 
  let sample1struct : [ String : Any ] = [
    "length": "10",
    "search": ["value": "", "regex": "false"],
    "_": "1493677490768",
    "draw": "1",
    "start": "0",
    "order": [["dir": "asc", "column": "0"]],
    "columns": [
      [ "orderable": "true", "name": "", "data": "login",
        "search": ["value": "", "regex": "false"], "searchable": "true"],
      [ "orderable": "true", "name": "", "data": "name",
        "search": ["value": "", "regex": "false"], "searchable": "true"],
      [ "orderable": "true", "name": "", "data": "cities",
        "search": ["value": "", "regex": "false"], "searchable": "true"]
    ]
  ]
  
  let sample1 = "draw=1&columns%5B0%5D%5Bdata%5D=login&columns%5B0%5D%5Bname%5D=&columns%5B0%5D%5Bsearchable%5D=true&columns%5B0%5D%5Borderable%5D=true&columns%5B0%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B0%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B1%5D%5Bdata%5D=name&columns%5B1%5D%5Bname%5D=&columns%5B1%5D%5Bsearchable%5D=true&columns%5B1%5D%5Borderable%5D=true&columns%5B1%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B1%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B2%5D%5Bdata%5D=cities&columns%5B2%5D%5Bname%5D=&columns%5B2%5D%5Bsearchable%5D=true&columns%5B2%5D%5Borderable%5D=true&columns%5B2%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B2%5D%5Bsearch%5D%5Bregex%5D=false&order%5B0%5D%5Bcolumn%5D=0&order%5B0%5D%5Bdir%5D=asc&start=0&length=10&search%5Bvalue%5D=&search%5Bregex%5D=false&_=1493677490768"

  let queryKeyNested = "foo[bar][baz]"
    // 'foo[bar][baz]=foobarbaz' -> [ "foo": [ "bar": [ "baz": "foobarbaz" ] ] ]
  
  let queryKeyArray   = "a[]"
    // 'a[]=b&a[]=c')            -> [ "a": [ "b", "c" ] ]
  
  let queryKeyIndexedArray = "a[1]"
    // 'a[1]=b&a[3]=c'           -> [ "a": [ nil, "b", nil, "c" ] ]  (max: 20)
  
  let queryKeyDotted = "a.b"
    // 'a.b=c' (allowsDot)       -> [ "a": [ "b": "c" ] ]
  
  let queryKeyArrayOfObjects = "a[][b]"
    // 'a[][b]=c'                -> [ "a": [ [ "b": "c" ] ] ]
  
  func testQueryStringParsing() throws {
    let qp = querystring.parse(sample1)
    print("QP: \(qp)")
    
    XCTAssertNotNil(qp["search[value]"])
    XCTAssertEqual(qp["length"] as? String, "10")
  }
  
  
  // MARK: - QS tests
  
  func testNestedQS() throws {
    let parameters = qs.parse("foo[bar][baz]=foobarbaz")
    XCTAssertEqual(parameters.count, 1)
    
    let o1 = parameters["foo"]
    XCTAssertNotNil(o1)
    XCTAssert(o1 is Dictionary<String, Any>)
    
    let o2 = (o1 as! Dictionary<String, Any>)["bar"]
    XCTAssertNotNil(o2)
    XCTAssert(o2 is Dictionary<String, Any>)

    let o3 = (o2 as! Dictionary<String, Any>)["baz"]
    XCTAssertNotNil(o3)
    XCTAssert(o3 is String)
    XCTAssertEqual(o3 as! String, "foobarbaz")
  }
  
  func testSimpleArrayQS() throws {
    let parameters = qs.parse("a[]=b&a[]=c")
    XCTAssertEqual(parameters.count, 1)
    
    let o1 = parameters["a"]
    XCTAssertNotNil(o1)
    XCTAssert(o1 is Array<Any>)
    
    let o1a = o1 as! Array<Any>
    XCTAssertEqual(o1a.count, 2)
    XCTAssert(o1a.contains(where: { $0 as? String == "b" }))
    XCTAssert(o1a.contains(where: { $0 as? String == "c" }))
  }
  
  func testIndexedArrayQS() throws {
    let parameters = qs.parse("a[1]=b&a[3]=c")
    XCTAssertEqual(parameters.count, 1)

    let o1 = parameters["a"]
    XCTAssertNotNil(o1)
    XCTAssert(o1 is Array<Any>)
    
    let o1a = o1 as! Array<Any>
    XCTAssertEqual(o1a.count, 4)
    XCTAssertEqual(o1a[1] as? String, "b")
    XCTAssertEqual(o1a[3] as? String, "c")
  }
  
  func testArrayOfObjectsQS() throws {
    // 'a[][b]=c'                -> [ "a": [ [ "b": "c" ] ] ]
    let parameters = qs.parse("a[][b]=c&a[][c]=42")
    XCTAssertEqual(parameters.count, 1)
    
    let o1 = parameters["a"]
    XCTAssertNotNil(o1)
    XCTAssert(o1 is Array<Any>)
    
    let o1a = o1 as! Array<Any>
    XCTAssertEqual(o1a.count, 2)
    
    let o2 = o1a[0]
    XCTAssert(o2 is Dictionary<String, Any>)
    let o2t = o2 as! Dictionary<String, Any>
    XCTAssertEqual(o2t.count, 1)
    XCTAssertEqual(o2t["b"] as? String, "c")
    
    let o3 = o1a[1]
    XCTAssert(o3 is Dictionary<String, Any>)
    let o3t = o3 as! Dictionary<String, Any>
    XCTAssertEqual(o3t.count, 1)
    XCTAssertEqual(o3t["c"] as? String, "42")
  }
  
  func testDataTablesQS() throws {
    let parameters = qs.parse(sample1)
    XCTAssertEqual(parameters.count, 7)
    
    XCTAssertEqual(parameters["length"] as? String, "10")
    XCTAssertEqual(parameters["draw"]   as? String, "1")
    XCTAssertEqual(parameters["start"]  as? String, "0")
    XCTAssertEqual(parameters["_"]      as? String, "1493677490768")

    let columns = parameters["columns"]
    XCTAssertNotNil(columns)
    XCTAssert(columns is Array<Any>)
    let tColumns = columns as! Array<Any>
    XCTAssertEqual(tColumns.count, 3)
    
    let col0 = tColumns[0]
    XCTAssert(col0 is Dictionary<String, Any>)
    let col0t = col0 as! Dictionary<String, Any>
    XCTAssertEqual(col0t.count, 5)
    
    XCTAssertEqual(col0t["orderable"]  as? String, "true")
    XCTAssertEqual(col0t["searchable"] as? String, "true")
    XCTAssertEqual(col0t["name"]       as? String, "")
    XCTAssertEqual(col0t["data"]       as? String, "login")
    
    let col0search = col0t["search"]
    XCTAssert(col0search is Dictionary<String, Any>)
    let col0searchT = col0search as! Dictionary<String, Any>
    XCTAssertEqual(col0searchT.count, 2)
    XCTAssertEqual(col0searchT["value"] as? String, "")
    XCTAssertEqual(col0searchT["regex"] as? String, "false")
  }
  
  
  // MARK: - KeyPath parser tests
  
  func testNestedKey() throws {
    let keyPath = qs.parseKeyPath(queryKeyNested, allowsDot: false)
    XCTAssertEqual(keyPath.count, 3)
    
    if case .Key(let value) = keyPath[0] { XCTAssertEqual(value, "foo") }
    else { XCTAssert(false, "not a string key") }

    if case .Key(let value) = keyPath[1] { XCTAssertEqual(value, "bar") }
    else { XCTAssert(false, "not a string key") }

    if case .Key(let value) = keyPath[2] { XCTAssertEqual(value, "baz") }
    else { XCTAssert(false, "not a string key") }
  }
  
  func testArrayKey() throws {
    let keyPath = qs.parseKeyPath(queryKeyArray, allowsDot: false)
    XCTAssertEqual(keyPath.count, 2)
    
    if case .Key(let value) = keyPath[0] { XCTAssertEqual(value, "a") }
    else { XCTAssert(false, "not a string key") }
    
    if case .Array = keyPath[1] { }
    else { XCTAssert(false, "not an array key") }
  }
  
  func testIndexedArrayKey() throws {
    let keyPath = qs.parseKeyPath(queryKeyIndexedArray, allowsDot: false)
    XCTAssertEqual(keyPath.count, 2)
    
    if case .Key(let value) = keyPath[0] { XCTAssertEqual(value, "a") }
    else { XCTAssert(false, "not a string key") }
    
    if case .Index(let value) = keyPath[1] { XCTAssertEqual(value, 1) }
    else { XCTAssert(false, "not an index key") }
  }
  
  func testDottedDisabled() throws {
    let keyPath = qs.parseKeyPath(queryKeyDotted, allowsDot: false)
    XCTAssertEqual(keyPath.count, 1)
    
    if case .Key(let value) = keyPath[0] { XCTAssertEqual(value, "a.b") }
    else { XCTAssert(false, "not a string key") }
  }
  
  func testDottedEnabled() throws {
    let keyPath = qs.parseKeyPath(queryKeyDotted, allowsDot: true)
    XCTAssertEqual(keyPath.count, 2)
    
    if case .Key(let value) = keyPath[0] { XCTAssertEqual(value, "a") }
    else { XCTAssert(false, "not a string key") }
    
    if case .Key(let value) = keyPath[1] { XCTAssertEqual(value, "b") }
    else { XCTAssert(false, "not a string key") }
  }
  
  func testArrayOfObjects() throws {
    let keyPath = qs.parseKeyPath(queryKeyArrayOfObjects, allowsDot: false)
    XCTAssertEqual(keyPath.count, 3)
    
    if case .Key(let value) = keyPath[0] { XCTAssertEqual(value, "a") }
    else { XCTAssert(false, "not a string key") }
    
    if case .Array = keyPath[1] { }
    else { XCTAssert(false, "not an array key") }
    
    if case .Key(let value) = keyPath[2] { XCTAssertEqual(value, "b") }
    else { XCTAssert(false, "not a string key") }
  }
  
  func testQueryKeyDepthLimit() throws {
    let keyPath = qs.parseKeyPath("a[b][c][d]", depth: 1, allowsDot: false)
    XCTAssertEqual(keyPath.count, 3)
    
    print("Keypath: \(keyPath)")
    
    if case .Key(let value) = keyPath[0] { XCTAssertEqual(value, "a") }
    else { XCTAssert(false, "not a string key") }

    if case .Key(let value) = keyPath[1] { XCTAssertEqual(value, "b") }
    else { XCTAssert(false, "not a string key") }

    if case .Key(let value) = keyPath[2] { XCTAssertEqual(value, "[c][d]") }
    else { XCTAssert(false, "not a string key") }
  }
  
}

